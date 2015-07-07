# Israel Supermarket Chain Data 
Last week a new law went into affect forcing all the major Israel Supermarket Chains to publish all prices and promotions so consumers can compare prices and lower prices through transparency. The full info (Google translated from Hebrew) of the law can be found [here](https://goo.gl/nan0Is)

The files instead of being in csv format were given to the public in nonuniform gzipped xml files. To say the chains did not act in good faith would be an understatement. The idea behind such a bad formatting scheme is that the government wanted to have private companies make apps so the consumers can access the data through a third party.

Instead R can be used to read the data and have the public actually look at the raw data in data.frames or csv exports

The example files:

  - mega_20150521.rdata: data from one full day of mega
  - mega_prices_slice.csv first 1000 rows from full day of prices in csv format


The Layout

15 Out of 19 chain stores have been coded to retrieve the data and convert them to dataframes

|    ChainId    |      ChainName       |
|:-------------:|:--------------------:|
| 7290027600007 |        שופרסל        |
| 7290055755557 |     עדן טבע מרקט     |
| 7290058140886 | רמי לוי שיווק השקמה  |
| 7290103152017 |       אושר עד        |
| 7290492000005 |       Dor Alon       |
| 7290633800006 |         קואפ         |
| 7290700100008 |    כל בו חצי חינם    |
| 7290725900003 | יינות ביתן מרכז הרשת |
| 7290785400000 |      קשת טעמים       |
| 7290873900009 |       סופר דוש       |
| 7290055700007 |       רשת מגה        |
| 7290058140886 | רמי לוי שיווק השקמה  |
| 7290058179503 |      מחסני להב       |
| 7290661400001 |      מחסני השוק      |
| 7290696200003 |       ויקטורי        |

The code in mega_gis.r is the raw code to create a function in which the user input the distance willing to travel from current geocode and all stores are filtered accordingly.

  - Data is read for only those stores
  - User can filter basket of items wishes to purchase
  - The gas cost is taken into account as a function of distance from the geocode in the final price (price from transportation auuthority site)
  
The folder stat_polygon_gis are shp files of the 2008 CBS stat polygons