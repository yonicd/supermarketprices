# Israel Supermarket Chain Data 
Last week a new law went into affect forcing all the major Israel Supermarket Chains to publish all prices and promotions so consumers can compare prices and lower prices through transparency. The full info (Google translated from Hebrew) of the law can be found [here](https://goo.gl/nan0Is)

The files instead of being in csv format were given to the public in nonuniform gzipped xml files. To say the chains did not act in good faith would be an understatement. The idea behind such a bad formatting scheme is that the government wanted to have private companies make apps so the consumers can access the data through a third party.

Instead R can be used to read the data and have the public actually look at the raw data in data.frames or csv exports

In the example files folder:

  - mega_20150521.rdata: data from one full day of mega
  - mega_prices_slice.csv first 1000 rows from full day of prices in csv format

In the Stores folder:

XML examples of all the stores in each chain store and a combined dataframe of the files and a csv version.


The Layout

16 Out of 18 chain stores have been coded to retrieve the data and convert them to dataframes. 

  - The remaining two
    - FreshMarket (Broken Link)
    - TivTaam (No Data)


|    chainid    |      chainname       |  provider  |
|:-------------:|:--------------------:|:----------:|
| 7290492000005 |       Dor Alon       |  cerberus  |
| 7290103152017 |       Osher Ad        |  cerberus  |
| 7290700100008 |    ColBo Hazi Hinam    |  cerberus  |
| 7290873900009 |       Super Dash       |  cerberus  |
| 7290803800003 |   Supershuk Yohananof    |  cerberus  |
| 7290785400000 |      Keshet Taamim       |  cerberus  |
| 7290058140886 | Rami Levi Shivuk Shikma  |  cerberus  |
| 7290696200003 |       Victory        |   nibit    |
| 7290661400001 |      Machsanei HaShuk      |   nibit    |
| 7290058179503 |      Machsanei Lahav       |   nibit    |
| 7290725900003 | Yeinot Bitan |  private   |
| 7290055755557 |     Eden Teva Market     |  private   |
| 7290027600007 |        Shufersal        |  private   |
| 7290058140886 |      Zol VeBegadol      |  private   |
| 7290633800006 |         Coop         |  private   |
| 7290055700007 |       Mega        |  private   |

The code in mega_gis.r is the raw code to create a function in which the user input the distance willing to travel from current geocode and all stores are filtered accordingly.

  - Data is read for only those stores
  - User can filter basket of items wishes to purchase
  - The gas cost is taken into account as a function of distance from the geocode in the final price (price from transportation auuthority site)
  
The folder stat_polygon_gis are shp files of the 2008 CBS stat polygons