"""Generate English word-frequency scores from a pinned wordfreq data snapshot."""

import argparse
import gzip
import hashlib
import re
from pathlib import Path

import msgpack

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "lib" / "Shared" / "words" / "english_frequency_scores.dart"
SOURCES = (
    ("english_word_list.dart", ("englishWordList",)),
    (
        "english_plurals.dart",
        (
            "englishRegularPlurals",
            "englishIrregularPlurals",
            "englishIndependentHeadwords",
        ),
    ),
    (
        "english_forms.dart",
        (
            "englishSourceHeadwords",
            "englishSourceRegularPlurals",
            "englishSourceIrregularPlurals",
            "englishSourceVerbForms",
            "englishSourceDescriptiveForms",
        ),
    ),
)
WORDFREQ_COMMIT = "912caf64b657478d1dff1138efdc078947d54bb1"
ENGLISH_DATA_SHA256 = "dffae8066b78dce0a6667cf5f58e567054f902674667090a7ac8a8a44628b05c"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("data", type=Path, help="wordfreq large_en.msgpack.gz")
    args = parser.parse_args()
    data = args.data.read_bytes()
    if hashlib.sha256(data).hexdigest() != ENGLISH_DATA_SHA256:
        raise ValueError(f"Unexpected wordfreq data SHA-256: {args.data}")
    buckets = msgpack.unpackb(gzip.decompress(data), raw=False)
    if buckets[0] != {"format": "cB", "version": 1}:
        raise ValueError("Unexpected wordfreq frequency format")
    corpus_scores = {
        word: 900 - index
        for index, bucket in enumerate(buckets[1:])
        for word in bucket
        if index < 900
    }

    words = set()
    for filename, names in SOURCES:
        source = (ROOT / "lib" / "Shared" / "words" / filename).read_text(
            encoding="utf-8"
        )
        for name in names:
            match = re.search(rf"{name}\s*=\s*\"\"\"(.*?)\"\"\"", source, re.S)
            if match is None:
                raise ValueError(f"Missing {name} in {filename}")
            words.update(word.upper() for word in match[1].splitlines())

    scores = {word: corpus_scores.get(word.lower(), 0) for word in sorted(words)}
    entries = "".join(
        f"  {word!r}: {score},\n"
        for word, score in scores.items()
        if score > 0
    )
    OUTPUT.write_text(
        "// Generated from wordfreq English large-list frequency bins at "
        f"{WORDFREQ_COMMIT}; no bundled quotes are used.\n"
        "// Frequency data: CC BY-SA 4.0. See THIRD_PARTY_NOTICES.md.\n"
        "const Map<String, int> englishFrequencyScores = {\n"
        + entries
        + "};\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Generated {sum(score > 0 for score in scores.values())} scored words")


if __name__ == "__main__":
    main()
