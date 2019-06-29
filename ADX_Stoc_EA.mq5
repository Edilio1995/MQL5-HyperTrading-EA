//+------------------------------------------------------------------+
//|                                                  ADX_Stoc_EA.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include<Trade\Trade.mqh>
CTrade trade;
int adxDefinition;
int stochasticDefinition;
double Bid,Ask;
int               bolliger_handle;
double            upper_buf[];
double            middle_buf[];
double            lower_buf[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   bolliger_handle=iBands(_Symbol,_Period,20,0,2,PRICE_CLOSE);
   ChartIndicatorAdd(ChartID(),0,bolliger_handle);
   ArraySetAsSeries(middle_buf,true);
   ArraySetAsSeries(upper_buf,true);
   ArraySetAsSeries(lower_buf,true);
   adxDefinition=iADX(_Symbol,_Period,14);
   stochasticDefinition=iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH);
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
   //Comment(Digits());
//variabili di gestione
   int nPosition=numberOfPosition();

//Aggiornamento offerta e domanda
   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

//Calcolo valori indicatore ADX
   double myPriceArray[];
      
   
   ArraySetAsSeries(myPriceArray,true);
   CopyBuffer(adxDefinition,0,0,20,myPriceArray);
//Valore adx per la candela corrente
   double ADXValue=NormalizeDouble(myPriceArray[0],2);
   Print("ADX VALUE: ",ADXValue);

//Calcolo valori indicatori stocastico
   string signal="";
   double KArray[];
   double DArray[];
   ArraySetAsSeries(KArray,true);
   ArraySetAsSeries(DArray,true);
   CopyBuffer(stochasticDefinition,0,0,20,KArray);
   CopyBuffer(stochasticDefinition,0,0,20,DArray);
   double KValue0=KArray[0];
   double KValue1=KArray[1];

   double DValue0=DArray[0];
   double DValue1=DArray[1];

//Calcolo valori bande di bollinger

   CopyBuffer(bolliger_handle,0,0,20,middle_buf);
   CopyBuffer(bolliger_handle,1,0,20,upper_buf);
   CopyBuffer(bolliger_handle,2,0,20,lower_buf);
   double middleValue0=middle_buf[0];
   double upperValue0 = upper_buf[0];
   double lowerValue0 = lower_buf[0];

   double middleValue1= middle_buf[1];
   double upperValue1 = upper_buf[1];
   double lowerValue1 = lower_buf[1];

  double bbw=(upperValue0-lowerValue0)*MathPow(10,Digits());
   Print("BBW: ",bbw);

   //Condizione di squeeze 
   if(bbw>=100)
     {
     //Inizio valutazione per posizioni iniziali
      if(nPosition==0)
        {
         if(DValue0<=20 && ADXValue<30)
           {
            if((KValue0-KValue1)>0)
              {
               trade.Buy(0.05,_Symbol,Ask,0,0,NULL);
               Comment("Compro");
              }
           }
         if(DValue0>=80 && ADXValue<30)
           {
            if((KValue0-KValue1)<0)
              {
               trade.Sell(0.05,_Symbol,Bid,0,0,NULL);
               Comment("Vendo");
              }
           }
        }
      //Continuo valutazioni  
      else
        {
         if(DValue0<=20 && ADXValue<30)
           {
            if((KValue0-KValue1)>0)
              {
               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
                 {
                  closeAllPosition();
                  trade.Buy(0.05,_Symbol,Ask,0,0,NULL);
                 }
              }
           }
         if(KValue0>=80 && ADXValue<30)
           {
            if((KValue0-KValue1)<0)
              {

               if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
                 {
                  closeAllPosition();
                  trade.Sell(0.05,NULL,Bid,0,0,NULL);
                 }
              }
           }

        }
     }else{
      closeAllPosition();
     }
  }
//+------------------------------------------------------------------+

void closeAllPosition()
  {
   int i=PositionsTotal()-1;
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

     {
      string symbol=PositionGetSymbol(i);
      if(Symbol()==symbol)
        {
         PositionCur+=1;
        }
     }
   return PositionCur;
  }
//+------------------------------------------------------------------+
