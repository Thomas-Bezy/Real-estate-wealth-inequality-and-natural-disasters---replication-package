
Repo supporting Bézy 2026 "Real Estate Wealth Inequality and Exposure to Natural Disasters" available at: https://wid.world/www-site/uploads/2025/07/WorldInequalityLab_WP2025_16_Real-Estate-Wealth-Inequality-and-Exposure-to-Natural-Disasters_Final.pdf.

Results from the paper are in the `Figures` folder. Codes to replicate results are in the `Scripts` folder. Publicly available data are stored in the `Data` folder. The folders `Raw_datasets`, `Boundaries_separate_files`, and `BdF_raw_datasets` are empty but must be kept for the codes to work. Most data are only available in restricted access:

- Information on housing market characteristics comes from the FIDELI dataset developed by the French Institute of Statistics (INSEE) and is available through secured access: https://www.casd.eu/en/source/housing-and-individual-demographic-file/. 
- House prices data are available in restricted access on request on the Cerema website: https://datafoncier.cerema.fr/dv3f. 
- Survey data on insurance spending comes from the Budget des familles dataset, also available through secured access: https://www.casd.eu/en/source/household-budget-survey/.

The codes require using Stata, R, SAS, and Python within QGIS.

## How to replicate results
1. Download this repository and unzip the data folder.
2. Obtain the restricted access data through the Centre d'Accès Sécurisé aux Données (CASD) and the Cerema website. Store these data in the `Data` folder.
3. Download the maps of exposure from https://www.georisques.gouv.fr/donnees/bases-de-donnees/retrait-gonflement-des-argiles-version-2026 and https://www.georisques.gouv.fr/donnees/
bases-de-donnees/zonages-inondation-rapportage-2020. Unzip them and put them in the Data folder.
4. Run the codes from `Scripts/1Data cleaning main dataset` and `Scripts/2Data cleaning insurance premiums` to prepare the data. More details on the structure of these scripts are available below. Update the working directories in each code.
5. Run the codes from `Scripts/3Results` to produce the figures. Update the working directories in each code.


## Folder structure - 1Data cleaning main dataset

1) Preparing the FIDELI administrative data on dwellings

`1.1Cleaning_admin_data.sas` and `1.2Add_owners_information.sas` prepare the FIDELI dataset for the analysis.


2) Preparing the exposure to risks datasets

`2.1Prepare_exposure_to_risks.R` prepares the exposure datasets. `2.2Code_exposure_TRI.py` and `2.3Code_exposure_RGA.py` need to be run in the Python console in QGIS to merge the coordinates from FIDELI with the maps of exposure to risks. `2.4Concatenate_exposure.R` and `2.5Unify_exposure_datasets.do` concatenate the separated exposure datasets. 


3) Merging FIDELI with the exposure to risks datasets

`3Merge_admin_with_exposure.do` merges the cleaned FIDELI dataset with the exposure datasets.

4) Merging with dwelling-level house prices

`4.1Extract_admin_data_for_merge_with_prices.do` extracts IDs that will be used for the merge with house prices. `4.2Extract_admin_data_for_merge_with_prices.do` merges with house prices. `4.3Final_merge.do` merges the demographics data from FIDELI with house prices.

