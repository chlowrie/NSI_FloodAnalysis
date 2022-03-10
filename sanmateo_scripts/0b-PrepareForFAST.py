'''
NiyamIT
COLIN LINDEMAN, GIS Developer
Proof of Concept - For Florida UCSC FAST

Last Update:2021-9-2
Created: 2020-1-28
Requirements:
   Python 3.7, Pandas (anaconda 64bit install)
   SQL Server 12.0.4237
'''

# Import necessary modules
import os
from pathlib import Path
import json
import pandas as pd
import argparse

'''
GET THE DATA...
'''
#INPUTS
# inputCsvPath = './SanMateoNSI_wgs84.csv'
# #OUTPUTS
# outputCsvPath = './SanMateoNSI_wgs84_prepped.csv'

#Read the input csv
def main(input, output):
    df_Csv = pd.read_csv(input, delimiter=",")
        
    #Set all columns to lowercase
    columnList = df_Csv.columns
    columnDict = {}
    for column in columnList:
        columnDict[column] = column.lower()
    df_Csv = df_Csv.rename(columns=columnDict)




    '''
    MODIFY THE DATA...
    This assumes the input NSI data has the same schema as when this script was created.
    '''

    #Update OCCTYPE: Use first 4 characters only except for RES3 where first 5 are required.
    def OccTypeFunction(OccTypeRaw):
        OccType = OccTypeRaw[0:4]
        if OccType == 'RES3':
            OccType = OccTypeRaw[0:5]
        return OccType
    # Add a new field and use the def above to calculate it...
    df_Csv['Occ'] = df_Csv.apply(lambda x: OccTypeFunction(x['occtype']), axis=1)

    #Update AreaSqFt: lookup to CDMS hz.sqftfactors...
    """Area can be estimated by dividing the ValStruct by the RSMeans per sqft replacement value by occupancy type.  
    Note that this has regional modification factors and factors for (RES1) single-family based on median incomes.  
    However, using the average for each provided by hzReplacementCost is recommended unless debris is a critical output.   
    For RES1 the RES1 tabs can provide a very detailed approach but for income ratios that are 0.85 to 1.25 of the national average, 
    using $127.37 and $133.05 for 1 and 2 story respectively is recommended.  For example RES1 area for single story = ValStruct/$127.37"""

    with open(os.path.join(Path(__file__).parent, "0b-supporting-MeansCost.json")) as f:
        MeansCostTable = json.load(f)
    def lookup_means_cost_by_occupancytype(OccType_FAST):
        means_cost = MeansCostTable.get(OccType_FAST)
        return means_cost
    def calculate_sqft(OccType_FAST, Val_Struct, N_Stories):
        if OccType_FAST == 'RES1' and N_Stories < 2:
            OccType_FAST = 'RES1_OneStory'
        elif OccType_FAST == 'RES1' and N_Stories == 2:
            OccType_FAST = 'RES1_TwoStory'
        elif OccType_FAST == 'RES1' and N_Stories > 2:
            OccType_FAST = 'RES1_ThreeStory'
        RSMeansPerSqftReplacementValue = lookup_means_cost_by_occupancytype(OccType_FAST)
        AreaSqFt = Val_Struct / RSMeansPerSqftReplacementValue
        return AreaSqFt
    df_Csv['Area'] = df_Csv.apply(lambda x: calculate_sqft(x['Occ'], x['val_struct'], x['n_stories']), axis=1)


    #FoundTypeId: convert text to numeric code
    def BasementIDFunction(Found_Type):
        if Found_Type == 'Pile':
            #Pile
            code = 1
        elif Found_Type == 'Pier':
            #Pier
            code = 2
        elif Found_Type == 'SolidWall':
            #Solid Wall
            code = 3
        elif Found_Type == 'Basement':
            #Basement/Garden
            code = 4
        elif Found_Type == 'Crawl':
            #Crawl Space
            code = 5
        elif Found_Type == 'Fill':
            #Fill
            code = 6
        elif Found_Type == 'Slab':
            #Slab on Grade
            code = 7
        else:
            code = 0
        return code
    # Add a new field and use the def above to calculate it...
    df_Csv['FoundationType'] = df_Csv.apply(lambda x: BasementIDFunction(x['found_type']), axis=1)
    

    '''
    MODIFY COLUMN NAMES FOR FAST
    '''
    #Val_Struct to Cost
    #N_Stories to NumStories
    #Found_Ht to FirstFloorHt
    #Val_Cont to ContentCost
    df_Csv.rename(columns={"val_struct": "Cost",\
                            "n_stories": "NumStories",\
                            "found_ht": "FirstFloorHt",\
                            "val_cont": "ContentCost"}, inplace=True)

    ''' 
    EXPORT TO CSV FILE
    '''

    #Export to csv...
    df_Csv.to_csv(output, index=False) #if no index set then pandas adds a headerless column that we don't want

    print('done')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=str)
    parser.add_argument('output', type=str)
    args = parser.parse_args()
    main(args.input, args.output)

