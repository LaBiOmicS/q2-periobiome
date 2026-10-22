"""Usage examples of the q2-periodontitis actions (qiime2.plugin.usage).

The example data are built in memory: four samples of two subjects before
and after therapy, with taxa from the Socransky complexes and the SMDI
signature. They run offline and are executed by the test suite.
"""
import biom
import numpy as np
import pandas as pd
import qiime2

TAXA = {
    "F1": "d__Bacteria; g__Porphyromonas; s__Porphyromonas_gingivalis",
    "F2": "d__Bacteria; g__Tannerella; s__Tannerella_forsythia",
    "F3": "d__Bacteria; g__Treponema; s__Treponema_denticola",
    "F4": "d__Bacteria; g__Fusobacterium; s__Fusobacterium_nucleatum",
    "F5": "d__Bacteria; g__Fretibacterium; s__Fretibacterium_sp._HMT_360",
    "F6": "d__Bacteria; g__Streptococcus; s__Streptococcus_sanguinis",
    "F7": "d__Bacteria; g__Actinomyces; s__Actinomyces_naeslundii",
    "F8": "d__Bacteria; g__Rothia; s__Rothia_dentocariosa",
    "F9": "d__Bacteria; g__Veillonella; s__Veillonella_parvula",
}
# features x samples: P1/P2 before (BL) and after (FU) therapy
COUNTS = np.array([
    [900, 40, 700, 60],
    [500, 30, 650, 20],
    [400, 10, 300, 15],
    [800, 300, 900, 250],
    [300, 5, 200, 0],
    [100, 900, 150, 1000],
    [50, 700, 80, 600],
    [30, 500, 40, 450],
    [200, 300, 250, 280],
])
SAMPLES = ["P1.BL", "P1.FU", "P2.BL", "P2.FU"]


def _table_factory():
    return qiime2.Artifact.import_data(
        "FeatureTable[Frequency]",
        biom.Table(COUNTS, list(TAXA), SAMPLES))


def _taxonomy_factory():
    df = pd.DataFrame({"Taxon": list(TAXA.values()),
                       "Confidence": [0.99, 0.98, 0.97, 0.95, 0.9, 0.85,
                                      0.92, 0.9, 0.96]},
                      index=pd.Index(list(TAXA), name="Feature ID"))
    return qiime2.Artifact.import_data("FeatureData[Taxonomy]", df)


def _metadata_factory():
    df = pd.DataFrame({"subject": ["P1", "P1", "P2", "P2"],
                       "visit": ["baseline", "follow-up", "baseline",
                                 "follow-up"]},
                      index=pd.Index(SAMPLES, name="sample-id"))
    return qiime2.Metadata(df)


def _collapse(use, **params):
    table = use.init_artifact("feature_table", _table_factory)
    taxonomy = use.init_artifact("taxonomy", _taxonomy_factory)
    return use.action(
        use.UsageAction("periodontitis", "collapse_complexes"),
        use.UsageInputs(table=table, taxonomy=taxonomy, **params),
        use.UsageOutputNames(complex_table="complexes", indices="indices",
                             mapping="mapping"))


def collapse_complexes_basic(use):
    complexes, indices, mapping = _collapse(use)
    complexes.assert_output_type("SocranskyComplexes")
    indices.assert_output_type("PeriodontalIndices")
    mapping.assert_output_type("SocranskyMapping")


def collapse_complexes_filtered(use):
    complexes, indices, mapping = _collapse(use, min_confidence=0.9,
                                            smdi_pseudocount=1e-6)
    indices.assert_output_type("PeriodontalIndices")


def delta_indices_paired(use):
    _, indices, _ = _collapse(use)
    metadata = use.init_metadata("metadata", _metadata_factory)
    delta, = use.action(
        use.UsageAction("periodontitis", "delta_indices"),
        use.UsageInputs(indices=indices, metadata=metadata,
                        subject_col="subject", group_col="visit",
                        baseline_group="baseline",
                        target_group="follow-up"),
        use.UsageOutputNames(delta_table="deltas"))
    delta.assert_output_type("SampleData[PeriodontalIndicesDelta]")


def summarize_by_group(use):
    complexes, indices, mapping = _collapse(use)
    metadata = use.init_metadata("metadata", _metadata_factory)
    viz, = use.action(
        use.UsageAction("periodontitis", "summarize"),
        use.UsageInputs(complexes=complexes, indices=indices,
                        mapping=mapping, metadata=metadata,
                        group_column="visit", subject_column="subject"),
        use.UsageOutputNames(visualization="summary"))
    viz.assert_output_type("Visualization")
