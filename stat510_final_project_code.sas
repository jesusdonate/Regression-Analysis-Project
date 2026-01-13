LIBNAME datasets "\\vdi-fileshare02\UEMprofiles\025926054\Desktop\STAT510 DATASETS";

DATA datasets.truck_data;
	infile "\\vdi-fileshare02\UEMprofiles\025926054\Desktop\STAT510 DATASETS\TRUCKING.txt" expandtabs;
	input PRICPTM DISTANCE WEIGHT PCTLOAD ORIGIN $ MARKET $ DEREG $ CARRIER $ PRODUCT LNPRICE;
	label 
		PRICPTM   = "Price per Ton-Mile (1980 dollars)"
		DISTANCE  = "Distance Traveled (hundreds of miles)"
		WEIGHT    = "Weight of Shipment (thousands of pounds)"
		PCTLOAD   = "Percent of Truck Load Capacity"
		ORIGIN    = "City of Origin (JAX or MIA)"
		MARKET    = "Destination Market Size (LARGE or SMALL)"
		DEREG     = "Deregulation in Effect (YES or NO)"
		CARRIER   = "Carrier Identifier"
		PRODUCT   = "Product Classification (100/150/200)"
		LNPRICE   = "Natural Log of Price per Ton-Mile";
if _n_ = 1 then delete;
RUN;


PROC PRINT data=datasets.truck_data(obs=10);
RUN;

PROC MEANS mean median var std min max data=datasets.truck_data;
RUN;

/*Key notes: 
	CARRIER contains only one value "B".
	DEREG is split evenly between pre- and post-deregulatiation
	PRODUCT consists of only 3 classes
*/
PROC FREQ data=datasets.truck_data;
tables ORIGIN MARKET DEREG CARRIER PRODUCT;
RUN;

/* Omitting PRICPTM and CARRIER */
DATA datasets.truck_data;
set datasets.truck_data;
drop PRICPTM CARRIER;
RUN;



/*Encoding categorical values*/
title "Encoding categorical values";
DATA datasets.truck_data;
set datasets.truck_data;

/* Encoding DEREG: 1 = YES (post-deregulation), 0 = NO (pre-deregulation) */
if DEREG = "YES" then DEREG_int = 1; else DEREG_int = 0;

/* Encoding ORIGIN: 1 = MIA, 0 = JAX */
if ORIGIN = "MIA" then ORIGIN_int = 1; else ORIGIN_int = 0;

/* Encoding MARKET: 1 = LARGE, 0 = SMALL */
if MARKET = "LARGE" then MARKET_int = 1; else MARKET_int = 0;

/* Encoding PRODUCT: PRODUCT=150 then PRODUCT_150=1, else PRODUCT_150=0
					 PRODUCT=200 then PRODUCT_200=1, else PRODUCT_200=0*/
if PRODUCT = 150 then PRODUCT_150 = 1; else PRODUCT_150 = 0;
if PRODUCT = 200 then PRODUCT_200 = 1; else PRODUCT_200 = 0;

/* Giving labels again */
label   
		ORIGIN_int  = "City of Origin (JAX=0 or MIA=1)"
		MARKET_int  = "Destination Market Size (LARGE=1 or SMALL=0)"
		DEREG_int   = "Deregulation in Effect (YES=1 or NO=0)"
		PRODUCT_150 = "Product Classification (150)"
		PRODUCT_200 = "Product Classification (200)";

drop DEREG ORIGIN MARKET PRODUCT;
rename DEREG_int=DEREG ORIGIN_int=ORIGIN MARKET_int=MARKET;
RUN;


PROC PRINT data=datasets.truck_data;
RUN;


title "Correlation Matrix";
PROC CORR data=datasets.truck_data;
RUN;


title "First Model";
PROC REG data=datasets.truck_data;
model LNPRICE = DISTANCE WEIGHT PCTLOAD DEREG ORIGIN MARKET PRODUCT_150 PRODUCT_200 /  VIF r influence;
output out=influence_data
           rstudent=rstudent
           cookd=cookd;
RUN;


DATA influential;
    set cookd;
	obs_n = _n_;
    if cookd > 0.032; *4/n = 4/134 = 0.032;
	keep cookd obs_n;
RUN;


title "Influential Points based on Cook's D for Model 1";
PROC PRINT data=influential noobs;
RUN;


DATA center;
set datasets.truck_data;
DISTANCE_C = DISTANCE - 2.931; * Centering DISTANCE to reduce correlation between its squared values;
RUN;

DATA datasets.truck_data2;
set center;
DISTANCE_C2 = DISTANCE_C * DISTANCE_C;
drop DISTANCE;
rename DISTANCE_C = DISTANCE
       DISTANCE_C2 = DISTANCE2;
RUN;


PROC CORR data=datasets.truck_data2;
var DISTANCE DISTANCE2;
RUN;


title "Model 2";
PROC REG data=datasets.truck_data2;
model LNPRICE = DISTANCE DISTANCE2 PCTLOAD DEREG ORIGIN PRODUCT_150 PRODUCT_200 /  VIF r influence;
output out=influence_data
           rstudent=rstudent
           cookd=cookd;
RUN;



DATA influential;
    set influence_data;
	obs_n = _n_;
    if cookd > 0.032; *4/n = 4/134 = 0.032;
	keep cookd obs_n;
RUN;


title "Influential Points based on Cook's D for Model 2";
PROC PRINT data=influential noobs;
RUN;
