import unittest

from tool.generate_english_plurals import accepted_noun_forms, is_regular_plural


class EnglishPluralGeneratorTest(unittest.TestCase):
    def test_includes_attested_alternatives_and_sense_variants(self):
        self.assertEqual(
            accepted_noun_forms("indexes, indices 1"),
            {"indexes", "indices"},
        )
        self.assertEqual(
            accepted_noun_forms(
                "media {communication}, mediums 1 {communication}, "
                "mediums {seance}"
            ),
            {"media", "mediums"},
        )
        self.assertEqual(
            accepted_noun_forms("people, persons 0.1"),
            {"people", "persons"},
        )

    def test_excludes_uncertain_or_unattributed_variants(self):
        self.assertEqual(accepted_noun_forms("aids, aides!< 1"), {"aids"})
        self.assertEqual(accepted_noun_forms("leaves, leafs 2"), {"leaves"})
        self.assertEqual(
            accepted_noun_forms("buses, bi~ 1, busses 1"),
            {"buses", "busses"},
        )
        self.assertEqual(accepted_noun_forms("axes, ax? 1, axis< 1"), {"axes"})
        self.assertEqual(accepted_noun_forms("forms, forms 1.1"), {"forms"})

    def test_classifies_alternate_spellings_without_hiding_irregulars(self):
        self.assertTrue(is_regular_plural("bus", "busses"))
        self.assertTrue(is_regular_plural("person", "persons"))
        self.assertFalse(is_regular_plural("index", "indices"))
        self.assertFalse(is_regular_plural("money", "monies"))


if __name__ == "__main__":
    unittest.main()
