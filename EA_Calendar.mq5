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

string            my_symbol;                               //variable for storing the symbol
ENUM_TIMEFRAMES   my_timeframe;                             //variable for storing the time frame
MqlRates PriceInfo[];
MqlDateTime dt_struct;
double Bid;
double Ask;
double difference;
bool calendarFlag=false;
datetime nextEventDat;
MqlCalendarValue values[];
MqlCalendarEvent events[];
MqlCalendarEvent event;
MqlCalendarValue value;
datetime nextEventDate;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(10);
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
//variabili di gestione
   int nPosition = numberOfPosition();
   datetime dtSer=TimeCurrent(dt_struct);

//Aggiornamento offerta e domanda
   Bid=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   Ask=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);

   ArraySetAsSeries(PriceInfo,true);
   CopyRates(Symbol(),Period(),0,20,PriceInfo);
   CopyBuffer(bolliger_handle,0,0,3,middle_buf);
   CopyBuffer(bolliger_handle,1,0,3,upper_buf);
   CopyBuffer(bolliger_handle,2,0,3,lower_buf);

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

   double bbw=(upperValue0-lowerValue0)*MathPow(10,Digits());
   Print("BBW: ",bbw);
   

//double bbwDifferenct = (upperValue1 - lowerValue1)*1000;
//Comment("BBW Difference", bbwDifferenct);

// Comment("Pi Average =",piAverage,"Actual difference= ",difference,"Bollinger Bandiwth ",bbw,"%");\
   if(calendarFlag==true)
     {
      Comment("Next Event [",event.name,"] Date: [",nextEventDate,"] Actual Date -> [",TimeLocal(),"]");
     }

//CONDIZIONE EVENTO CALENDARIO ECONOMICO
   if((calendarFlag==true) && (TimeCurrent()>nextEventDat))
     {
      //CONDIZIONE BANDE DI BOLLINGER
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
                     trade.Buy(0.05,_Symbol,Ask,(upperValue0-100 *_Point),(upperValue0+500*_Point),NULL);
                     PlaySound("OK.wav");
                    }
                 }
               else
                 {
                  trade.Buy(0.05,_Symbol,Ask,(upperValue0-100*_Point),(upperValue0+500*_Point),NULL);
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
                     trade.Sell(0.05,_Symbol,Bid,lowerValue0+100*_Point,(lowerValue0-500*_Point),NULL);
                     PlaySound("OK.wav");
                    }
                 }
               else
                 {
                  trade.Sell(0.05,_Symbol,Bid,lowerValue0+100*_Point,(lowerValue0-500*_Point),NULL);
                  PlaySound("OK.wav");
                 }
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
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   string EU_code="EU";
   datetime date_from=TimeCurrent();
   datetime date_to=0;
//--- request EU event history since 2018 year 
   Print(TimeLocal());
   if(CalendarValueHistory(values,TimeLocal(),NULL))
     {
      PrintFormat("Received event values for country_code=%s: %d",
                  EU_code,ArraySize(values));
      //--- decrease the size of the array for outputting to the Journal 
      ArrayResize(values,5);
      //--- display event values in the Journal 
      //    ArrayPrint(values);
      calendarFlag=true;
     }
   else
     {
      PrintFormat("Error! Failed to receive events for country_code=%s",EU_code);
      PrintFormat("Error code: %d",GetLastError());
     }
   for(int i=0; i<ArraySize(values); i++)
     {
      CalendarEventById(values[i].event_id,event);
      Print("Name",event.name);
      if(event.importance>=2)
        {
         Print("[Nome Evento: ",event.name," , Data: ",values[i].time," Importanza: ",event.importance);
         nextEventDate=values[i].time;
         Print(nextEventDate);
         return;
        }
     }
  }
//+------------------------------------------------------------------+
