# Headache PCA

## Setup

You are required to create a file "headacheData.xlsx" and a file "config.json".
The headacheData shall be an Excel Table with one sheet, having at least the 
two columns (with these titles) *Date* and *Strength*.
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
        "clienSecret": "...",
        "callbackURL": "https://example.com/headache-pca/login-callback",
        "autorizationURI": "https://www.fitbit.com/oauth2/authorize",
        "refreshTokenURI": "https://api.fitbit.com/oauth2/token"
    }
}
```