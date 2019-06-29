//+------------------------------------------------------------------+
//|                                                 Difference20.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include<Trade\Trade.mqh>
CTrade trade;

#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int               bolliger_handle;
double            upper_buf[];
double            middle_buf[];
double            lower_buf[];

                             //variable for storing the symbol
ENUM_TIMEFRAMES   my_timeframe;                             //variable for storing the time frame
MqlRates PriceInfo[];
MqlRates PriceDelta[];
MqlDateTime dt_struct;

double Bid;
double Ask;
double difference;
double previousDelta;
string my_symbol;  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   previousDelta = 1;
   bolliger_handle=iBands(my_symbol,my_timeframe,20,0,2,PRICE_CLOSE);
   ChartIndicatorAdd(ChartID(),0,bolliger_handle);
   ArraySetAsSeries(middle_buf,true);
   ArraySetAsSeries(upper_buf,true);
   ArraySetAsSeries(lower_buf,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   controlDelta("try");
//variabili di gestione
   int nPosition = numberOfPosition();
   datetime dtSer=TimeCurrent(dt_struct);
   Print("Digit",Digits());
//Aggiornamento offerta e domanda
   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   ArraySetAsSeries(PriceInfo,true);
   CopyRates(Symbol(),Period(),0,20,PriceInfo);
   CopyBuffer(bolliger_handle,0,0,20,middle_buf);
   CopyBuffer(bolliger_handle,1,0,20,upper_buf);
   CopyBuffer(bolliger_handle,2,0,20,lower_buf);

   double middleValue0= middle_buf[0];
   double upperValue0 = upper_buf[0];
   double lowerValue0 = lower_buf[0];

   double middleValue1= middle_buf[1];
   double upperValue1 = upper_buf[1];
   double lowerValue1 = lower_buf[1];
//Comment("UP: ",upperValue0," Down: ",lowerValue0," Middle: ", middleValue0, " Current price " ,PriceInfo[1].close);

//Calcolo del PI-Average 
   double piAverage=0;
   for(int i=0; i<19; i++)
     {
      piAverage=MathAbs(PriceInfo[i].close-PriceInfo[i+1].close);
     }
   piAverage=piAverage/20;
   difference=MathAbs(PriceInfo[0].close-PriceInfo[1].close);
//int magicNumber = Digits();
   double bbw=(upperValue0-lowerValue0)*MathPow(10,Digits());
   Print("BBW: ",bbw);
  // Comment("Bollinger Bandiwth ",bbw);

   if(bbw>=100)
     {
      //CONDIZIONE DI ROTTURA
      if(difference>=3*piAverage)
        {
         //Check a rialzo
         if(PriceInfo[0].close>upperValue0)
           {
            if(nPosition>0)
              {
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
                 {
                  closeAllPosition();
                  trade.Buy(0.10,_Symbol,Ask,0,0,NULL);
                  PlaySound("OK.wav");
                 }
               else 
                 {
                   //controlDelta("buy");
                 }
              }
            else
              {
               trade.Buy(0.10,_Symbol,Ask,0,0,NULL);
               PlaySound("OK.wav");
              }
           }
         //Check a ribasso
         if(PriceInfo[0].close<lowerValue0)
           {
            if(nPosition>0)
              {
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                 {
                  closeAllPosition();
                  trade.Sell(0.10,_Symbol,Bid,0,0,NULL);
                  PlaySound("OK.wav");
                 }
                else 
                 {
                   //controlDelta("sell");
                 }
              }
            else
              {
               trade.Sell(0.10,_Symbol,Bid,0,0,NULL);
               PlaySound("OK.wav");
              }
           }
        }
     }
   else
     {
      closeAllPosition();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllPosition()
  {
   int i=PositionsTotal()-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   while(i>=0)
     {
      if(trade.PositionClose(PositionGetSymbol(i))) i--;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int numberOfPosition()
  {
   int PositionCur=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      string symbol=PositionGetSymbol(i);
      if(Symbol()==symbol)
        {
         PositionCur+=1;
        }
     }
   return PositionCur;
  }

void controlDelta(string parameter){
   double piAver = 1.0;
   ArraySetAsSeries(PriceDelta,true);
   CopyRates(Symbol(),Period(),0,7,PriceDelta);
   for(int i=0; i<7; i++)
     {
      piAver=piAver + PriceDelta[i].close;
     }
   piAver=piAver/7;
   double diff = (piAver/previousDelta)*100;
   Comment("Previous: ", previousDelta, ", Actual: ", piAver, " Diff: ", diff);
   
   previousDelta = piAver;
  /* if(parameter == "buy" && piAver < curren){
      Print("STIAMO PERDENDO IN BUY ", previousDelta, " > ", piAver );
      //closeAllPosition();
      //previousDelta = 0;
   }
   else if(parameter == "sell" && piAver){
      Print("STIAMO PERDENDO IN SELL ", previousDelta, " < ", piAver );
   }*/
}

//+------------------------------------------------------------------+
