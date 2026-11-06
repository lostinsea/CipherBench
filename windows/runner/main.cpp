#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

struct InstanceMutex {
  HANDLE handle = nullptr;
  bool owned = false;

  void Close() {
    if (handle != nullptr) {
      if (owned) {
        ::ReleaseMutex(handle);
      }
      ::CloseHandle(handle);
      handle = nullptr;
      owned = false;
    }
  }

  ~InstanceMutex() { Close(); }
};

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  constexpr wchar_t kWindowTitle[] = L"Scioly Codebusters";
  InstanceMutex mutex{
      ::CreateMutexW(nullptr, TRUE, L"Local\\SciolyCodebustersSingleInstance"),
      false};
  const DWORD mutex_error = ::GetLastError();
  if (mutex.handle == nullptr) {
    const std::wstring error = L"Could not start Codebusters (Windows error " +
                               std::to_wstring(mutex_error) + L").";
    ::MessageBoxW(nullptr, error.c_str(), kWindowTitle, MB_OK | MB_ICONERROR);
    return EXIT_FAILURE;
  }
  mutex.owned = mutex_error != ERROR_ALREADY_EXISTS;
  if (mutex_error == ERROR_ALREADY_EXISTS) {
    for (int attempt = 0; attempt < 100; ++attempt) {
      HWND existing_window = Win32Window::FindExistingWindow(kWindowTitle);
      if (existing_window != nullptr && ::IsWindowVisible(existing_window) &&
          ::GetPropW(existing_window, Win32Window::kClosingWindowProperty) ==
              nullptr) {
        if (::IsIconic(existing_window)) {
          ::ShowWindow(existing_window, SW_RESTORE);
        }
        if (!::SetForegroundWindow(existing_window)) {
          FLASHWINFO flash{sizeof(flash), existing_window, FLASHW_TRAY, 3, 0};
          ::FlashWindowEx(&flash);
        }
        return EXIT_SUCCESS;
      }
      const DWORD result = ::WaitForSingleObject(mutex.handle, 100);
      if (result == WAIT_OBJECT_0 || result == WAIT_ABANDONED) {
        mutex.owned = true;
        break;
      }
      if (result == WAIT_FAILED) {
        const DWORD wait_error = ::GetLastError();
        mutex.Close();
        const std::wstring error = L"Could not check the running instance "
                                   L"(Windows error " +
                                   std::to_wstring(wait_error) + L").";
        ::MessageBoxW(nullptr, error.c_str(), kWindowTitle,
                      MB_OK | MB_ICONERROR);
        return EXIT_FAILURE;
      }
    }
    if (!mutex.owned) {
      mutex.Close();
      ::MessageBoxW(nullptr,
                    L"Codebusters is already running, but its window has not "
                    L"appeared. Close the other instance if it stays hidden.",
                    kWindowTitle, MB_OK | MB_ICONERROR);
      return EXIT_FAILURE;
    }
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1100, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
