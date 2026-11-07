# Third-party notices and outstanding rights checks

## JetBrains Mono fonts

The bundled JetBrains Mono fonts are licensed under the SIL Open Font License, Version 1.1. The [copyright notice and full license](licenses/OFL-JetBrainsMono.txt) come from [Google Fonts' JetBrains Mono distribution](https://github.com/google/fonts/tree/main/ofl/jetbrainsmono). Include that file with every Windows release.

## English plural inflections

The English additions in `lib/Shared/words/english_plurals.dart` are generated from [AGID 2016.01.19](https://sourceforge.net/projects/wordlist/files/AGID/2016.01.19/) noun inflections and checked against the [ESDB en_US 2026.02.25 size-60 word list](https://github.com/en-wl/wordlist-diff/tree/rel-2026.02.25) and noun lemmas in [Open English WordNet 2025](https://github.com/globalwordnet/english-wordnet/releases/tag/2025-edition). The generator considers all comma-separated AGID noun alternatives, but rejects uncertain forms (AGID suffix flags or variant level 2 and higher) and forms whose singular is not a WordNet noun lemma. It requires ESDB attestation and produces 2,262 additional regular plurals, 34 additional irregular plurals, and 144 independently attested headwords. The original dictionary is never filtered, and irregular plurals and independent headwords stay visible with the regular-plural toggle off. This remains a selective, source-checked list, not a comprehensive English dictionary; the sources attest spellings, inflections, and independent lexical entries, but do not prove every word is common or suitable for every puzzle. The [ESDB copyright and permission notice](licenses/ESDB-Copyright.txt), [AGID README and credits](licenses/AGID-README.txt), and [WordNet attribution and CC BY 4.0 license link](licenses/OEWN-2025-ATTRIBUTION.txt) are bundled as Windows app assets.

Regenerate with `python tool/generate_english_plurals.py <agid-2016.01.19.tar.gz> <en_US.txt> <english-wordnet-2025.xml.gz>` using those exact source versions. The SHA-256 hashes of the source downloads are `15d2d792d309d2dc838bf75d8abcd3feb36708c219dc5158d4fff70b89e601d1`, `4ff7e0b6d86763e1e042ffd746e94cdf4432618702deac303a1669e2a838db04`, and `9ca6d1dcb75f822fdd66617f7d9da48142ace38dd544d6ad5e2feca1674ad3fe`, respectively.

## Other bundled content

**RELEASE_BLOCKED:** The upstream music, sound effects, quote collections, word lists, and original logo are not covered by the JetBrains Mono license. Their provenance and redistribution permissions have not yet been established. The original logo remains in the Windows Flutter asset bundle even though the Windows UI displays the new CipherBench logo. Do not publish a binary until these rights have been checked and the required notices included; then replace this paragraph with the verified provenance and notices.

Flutter and package dependency notices are generated into `data\flutter_assets\NOTICES.Z` in the Windows build; include that `data` directory when distributing the app.
