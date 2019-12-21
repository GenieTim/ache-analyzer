% MAIN do analysis on headache dates
close all; clear variables;
% autoloading :P
addpath('./classes', './functions');

long = 8.630744305025708;
lat = 47.2473242478023;

analsyisProvider = Analyzer();
analsyisProvider = analsyisProvider.addDataByDataProvider(DarkSkyAPIClient(long, lat));
analsyisProvider = analsyisProvider.addDataByDataProvider(FitbitAPIClient());
%[loadings,scores,vexpZ,tsquared,vexpX,mu] = analsyisProvider.runPrincipalComponentAnalysis();
tree = analsyisProvider.runDecisionTree();