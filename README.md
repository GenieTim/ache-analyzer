# Ache Analyzer 

This is a proof of concept, or rather a personal experiment, 
to analyze and find correlations between aches, such as a headache, and
data, such as weather or the one collected by a FitBit watch.

Proof of concept insofar as Matlab might be the wrong choice for the data 
aggregation part in this software, given that there is no easy way to handle OAuth, 
for example for the one provided by FitBit, 
whereas another language such as Phyton could have provided simple libraries. 

Note that depending on your data structures this program may not always work. 
Feel free to contribute to [functions/simplifyTable](functions/simplifyTable) to fix this issue.

## Setup

You are required to create a file "headacheData.xlsx" and a file "config.json" 
(run setup.sh to let it do it for you).
The headacheData shall be an Excel Table with one sheet, having at least the 
two columns (with these titles) *time* (being the datetime) and *dolor* 
(being the badness/strength of the ache).
The config.json file may have different keys, depending on the data you want to analyse too.
It may look like this (replace the ... with your own keys):

```json
{
    "darkSky": {
        "apiSecret": "...",
        "apiURL": "https://api.darksky.net/forecast/%s/%f,%f,%d"
    },
    "fitBit": {
        "clientID": "...",
        "clientSecret": "...",
        "callbackURI": "https://example.com/headache-pca/login-callback",
        "callbackSecret": 123456789,
        "authorizationURI": "https://www.fitbit.com/oauth2/authorize",
        "refreshTokenURI": "https://api.fitbit.com/oauth2/token"
    }
}
```

Additionally, you may edit main.m to add/remove unused data provider or 
desired analysi

## Usage

After download & setup, you can just use MatLab to run `main.m`.
Make sure to adapt it to the analysis you want to actually run. 
Depending on your data, you might need to interact from time to time; 
FitBit for example requires you to enter the access_token for the API, 
as there is currently no (to me known) way to access the redirect URL using Matlab.