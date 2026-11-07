"""Generate CipherBench's plural data from AGID and the ESDB US wordlist."""

import gzip
import hashlib
import re
import sys
import tarfile
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "lib" / "Shared" / "words" / "english_plurals.dart"
ENGLISH = ROOT / "lib" / "Shared" / "words" / "english_word_list.dart"
# AGID includes rare noun senses of pronouns and mass nouns.
EXCLUDED = {"hers", "his", "its", "newses", "rices", "yours"}
EXCLUDED_IRREGULAR_STEMS = {"ban", "beef", "his", "yourself"}
SOURCE_HASHES = (
    "15d2d792d309d2dc838bf75d8abcd3feb36708c219dc5158d4fff70b89e601d1",
    "4ff7e0b6d86763e1e042ffd746e94cdf4432618702deac303a1669e2a838db04",
    "9ca6d1dcb75f822fdd66617f7d9da48142ace38dd544d6ad5e2feca1674ad3fe",
)


def verify_sources(paths: tuple[Path, Path, Path]) -> None:
    for path, expected in zip(paths, SOURCE_HASHES):
        digest = hashlib.sha256()
        with path.open("rb") as source:
            for block in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(block)
        if digest.hexdigest() != expected:
            raise ValueError(f"Unexpected source contents: {path}")


def wordnet_entries(archive: Path) -> tuple[set[str], set[str]]:
    noun_lemmas = set()
    headwords = set()
    with gzip.open(archive, "rb") as wordnet:
        for _, entry in ET.iterparse(wordnet, events=("end",)):
            if entry.tag == "LexicalEntry":
                lemma = entry.find("Lemma")
                if lemma is not None:
                    word = lemma.get("writtenForm", "").lower()
                    if re.fullmatch(r"[a-z]+", word):
                        headwords.add(word)
                        if lemma.get("partOfSpeech") == "n":
                            noun_lemmas.add(word)
                entry.clear()
            elif entry.tag == "Synset":
                entry.clear()
    return noun_lemmas, headwords


def accepted_noun_forms(inflections: str) -> set[str]:
    forms = set()
    for entry in inflections.split(", "):
        # AGID marks uncertain forms with suffix flags and level 2 or higher.
        form = re.fullmatch(
            r"([a-z]+)(?: (?:0(?:\.\d+)?|1))?(?: \{[^}]*\})?",
            entry,
        )
        if form is not None:
            forms.add(form[1])
    return forms


def is_regular_plural(singular: str, plural: str) -> bool:
    doubled_s = (
        singular + "ses"
        if singular.endswith("s") and not singular.endswith("ss")
        else ""
    )
    return plural in (
        singular + "s",
        singular + "es",
        singular[:-1] + "ies" if singular.endswith("y") else "",
        doubled_s,
    )


def main(archive: Path, common_words: Path, wordnet: Path) -> None:
    verify_sources((archive, common_words, wordnet))
    source = re.search(r'"""(.*?)"""', ENGLISH.read_text(encoding="utf-8"), re.S)
    if source is None:
        raise ValueError("English dictionary source has no word list")
    existing = {
        word.lower()
        for word in source[1].splitlines()
        if re.fullmatch(r"[a-z]+", word.lower())
    }
    attested = {
        word.lower() for word in common_words.read_text(encoding="utf-8").splitlines()
    }
    noun_lemmas, headwords = wordnet_entries(wordnet)

    regular = set()
    irregular = set()
    with tarfile.open(archive, "r:gz") as agid:
        data = agid.extractfile("agid-2016.01.19/infl.txt")
        if data is None:
            raise ValueError("AGID archive is missing infl.txt")
        for line in data.read().decode("latin-1").splitlines():
            noun = re.fullmatch(r"([a-z]+) N: (.+)", line)
            if noun is None or noun[1] not in existing or noun[1] not in noun_lemmas:
                continue
            for plural in accepted_noun_forms(noun[2]):
                singular = noun[1]
                if (
                    plural == singular
                    or plural not in attested
                    or plural in EXCLUDED
                ):
                    continue
                if is_regular_plural(singular, plural):
                    regular.add(plural)
                elif singular not in EXCLUDED_IRREGULAR_STEMS:
                    irregular.add(plural)

    regular.difference_update(irregular)
    independent = (regular & headwords) - existing
    regular.difference_update(existing | independent)
    irregular.difference_update(existing)
    output = (
        "// Generated from AGID 2016.01.19, ESDB en_US 2026.02.25 (size 60), "
        "and Open English WordNet 2025.\n"
        "// See tool/generate_english_plurals.py and THIRD_PARTY_NOTICES.md.\n"
        'final List<String> englishRegularPlurals =\n    """'
        + "\n".join(sorted(regular))
        + '"""\n        .split("\\n");\n\n'
        'final List<String> englishIrregularPlurals =\n    """'
        + "\n".join(sorted(irregular))
        + '"""\n        .split("\\n");\n\n'
        'final List<String> englishIndependentHeadwords =\n    """'
        + "\n".join(sorted(independent))
        + '"""\n        .split("\\n");\n'
    )
    OUTPUT.write_text(output, encoding="utf-8", newline="\n")
    print(
        f"Generated {len(regular)} additional regular plurals, "
        f"{len(irregular)} additional irregular plurals, and "
        f"{len(independent)} independent headwords"
    )


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit(
            "Usage: python tool/generate_english_plurals.py "
            "<agid-2016.01.19.tar.gz> <en_US.txt> "
            "<english-wordnet-2025.xml.gz>"
        )
    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
