"""Generate a quote-independent English dictionary from pinned lexical sources."""

import gzip
import re
import sys
import tarfile
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path

from generate_english_plurals import (
    EXCLUDED,
    EXCLUDED_IRREGULAR_STEMS,
    ROOT,
    accepted_noun_forms,
    is_regular_plural,
    verify_sources,
)


OUTPUT = ROOT / "lib" / "Shared" / "words" / "english_forms.dart"
ENGLISH = ROOT / "lib" / "Shared" / "words" / "english_word_list.dart"
PLURALS = ROOT / "lib" / "Shared" / "words" / "english_plurals.dart"


def dart_words(path: Path, name: str) -> set[str]:
    text = path.read_text(encoding="utf-8")
    match = re.search(rf"{name}\s*=\s*\"\"\"(.*?)\"\"\"", text, re.S)
    if match is None:
        raise ValueError(f"Missing word list {name} in {path}")
    return {word.lower() for word in match[1].splitlines()}


def wordnet_lemmas(path: Path) -> dict[str, set[str]]:
    lemmas = defaultdict(set)
    with gzip.open(path, "rb") as source:
        for _, entry in ET.iterparse(source, events=("end",)):
            if entry.tag == "LexicalEntry":
                lemma = entry.find("Lemma")
                if lemma is not None:
                    word = lemma.get("writtenForm", "").lower()
                    if re.fullmatch(r"[a-z]+", word):
                        lemmas[word].add(lemma.get("partOfSpeech", ""))
                entry.clear()
            elif entry.tag == "Synset":
                entry.clear()
    return lemmas


def descriptive_adverb(word: str, lemmas: dict[str, set[str]]) -> bool:
    if not word.endswith("ly") or "r" not in lemmas.get(word, set()):
        return False
    stem = word[:-2]
    candidates = {stem, stem + "e"}
    if word.endswith("ily"):
        candidates.add(word[:-3] + "y")
    if word.endswith("ically"):
        candidates.add(word[:-4])
    return any(lemmas.get(candidate, set()) & {"a", "s"} for candidate in candidates)


def write_list(name: str, words: set[str]) -> str:
    if not words:
        return f"final List<String> {name} = const [];\n"
    return (
        f'final List<String> {name} =\n    """'
        + "\n".join(sorted(words))
        + '"""\n        .split("\\n");\n'
    )


def main(archive: Path, common_words: Path, wordnet: Path) -> None:
    verify_sources((archive, common_words, wordnet))
    originals = dart_words(ENGLISH, "englishWordList")
    default = (
        originals
        | dart_words(PLURALS, "englishIrregularPlurals")
        | dart_words(PLURALS, "englishIndependentHeadwords")
    )
    existing_regular = dart_words(PLURALS, "englishRegularPlurals")
    attested = set(common_words.read_text(encoding="utf-8").splitlines())
    lemmas = wordnet_lemmas(wordnet)
    nouns, verbs, comparative = set(), set(), set()

    with tarfile.open(archive, "r:gz") as agid:
        data = agid.extractfile("agid-2016.01.19/infl.txt")
        if data is None:
            raise ValueError("AGID archive is missing infl.txt")
        for line in data.read().decode("latin-1").splitlines():
            match = re.fullmatch(r"([a-z]+) ([NVA]): (.+)", line)
            if match is None:
                continue
            stem, kind, forms = match.groups()
            if stem not in attested or stem not in lemmas:
                continue
            if kind == "N" and "n" not in lemmas[stem]:
                continue
            if kind == "V" and "v" not in lemmas[stem]:
                continue
            if kind == "A" and not lemmas[stem] & {"a", "s"}:
                continue
            for form in accepted_noun_forms(forms.replace(" | ", ", ")) & attested:
                if form == stem:
                    continue
                if kind == "N":
                    if form not in EXCLUDED:
                        nouns.add((stem, form))
                elif kind == "V":
                    verbs.add(form)
                else:
                    comparative.add(form)

    regular, irregular = set(), set()
    for stem, form in nouns:
        if is_regular_plural(stem, form):
            regular.add(form)
        elif stem not in EXCLUDED_IRREGULAR_STEMS:
            irregular.add(form)
    regular.difference_update(irregular)
    adverbs = {
        word for word in attested & lemmas.keys() if descriptive_adverb(word, lemmas)
    }
    descriptive = comparative | adverbs

    headwords = set()
    for word in attested & lemmas.keys():
        if word in default or len(word) < 3:
            continue
        if word in regular or word in existing_regular or word in irregular:
            headwords.add(word)
            continue
        derived_parts = set()
        if word in verbs:
            derived_parts.add("v")
        if word in comparative:
            derived_parts.update(("a", "s"))
        if word in adverbs:
            derived_parts.add("r")
        if lemmas[word] - derived_parts:
            headwords.add(word)

    new_headwords = headwords - default
    new_regular = {word for word in regular - existing_regular if len(word) >= 3}
    new_irregular = {word for word in irregular - default if len(word) >= 3}
    verbs = {word for word in verbs if len(word) >= 3 or word in default}
    output = (
        "// Generated from AGID 2016.01.19, ESDB en_US 2026.02.25, and "
        "Open English WordNet 2025; no bundled quotes are used.\n"
        "// See tool/generate_english_forms.py and THIRD_PARTY_NOTICES.md.\n"
        + write_list("englishSourceHeadwords", new_headwords)
        + "\n"
        + write_list("englishSourceRegularPlurals", new_regular)
        + "\n"
        + write_list("englishSourceIrregularPlurals", new_irregular)
        + "\n"
        + write_list("englishSourceVerbForms", verbs)
        + "\n"
        + write_list("englishSourceDescriptiveForms", descriptive)
    )
    OUTPUT.write_text(output, encoding="utf-8", newline="\n")
    print(
        f"Source pool: {len(new_headwords)} headwords, "
        f"{len(new_regular)} regular and {len(new_irregular)} irregular plurals, "
        f"{len(verbs)} verb and {len(descriptive)} descriptive forms"
    )


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: python tool/generate_english_forms.py "
            "<agid-2016.01.19.tar.gz> <en_US.txt> "
            "<english-wordnet-2025.xml.gz>"
        )
    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
