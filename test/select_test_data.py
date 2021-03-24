#!/bin/python3

import pandas as pd


df_data = pd.read_csv("full_test_metadata.tsv", sep="\t")
df_test = df_data[df_data.Experiment.isin(["ERX1320318", "ERX3440931", "SRX315307"])]
df_test.to_csv("test_metadata.tsv", sep="\t", index=False)
