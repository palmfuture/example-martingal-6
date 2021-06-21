#property copyright "Copyright 2021, palmfuture"
#property link      "https://palmfuture.space"
#property version   "6.00"
#property strict

//--- input parameter
extern string INPUT = "-------------INPUT PARAMETER-------------";
input double Lots = 0.1;
double LotExponent = 2;
int PipStep = 100;
int TakeProfit = 100;
input string CONFIG = "-------------CONFIG PARAMETER-------------";
input int Slippage = 3;
input int LotDemical = 2;
input int Magic = 1234;

double askPrice = MarketInfo(Symbol(), MODE_ASK);
double bidPrice = MarketInfo(Symbol(), MODE_BID);
double maxProfit = 0;
double maxLotSize = 0;
double maxLoss = 0;

int OnInit(){
   ObjectsDeleteAll();
   setComment();
   return(INIT_SUCCEEDED);
}

void setComment() {
   string comment_name = AccountName();
   string comment_number = IntegerToString(AccountNumber()); 
   string comment_balance = DoubleToString(AccountBalance(), 2);
   string comment_profit = DoubleToString(AccountProfit(), 2);
   string comment_max_lot_size = DoubleToString(maxLotSize, 2);
   string comment_max_loss = DoubleToString(maxLoss, 2);
   
   ObjectCreate("Name",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("Name",OBJPROP_CORNER,1);
   ObjectSet("Name",OBJPROP_XDISTANCE,20);
   ObjectSet("Name",OBJPROP_YDISTANCE,50);
   ObjectSetText("Name","Account Name : " + comment_name,8,"Tahoma", White);
   
   ObjectCreate("Number",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("Number",OBJPROP_CORNER,1);
   ObjectSet("Number",OBJPROP_XDISTANCE,20);
   ObjectSet("Number",OBJPROP_YDISTANCE,70);
   ObjectSetText("Number","Account Number : " + comment_number,8,"Tahoma", White);
   
   ObjectCreate("Balance",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("Balance",OBJPROP_CORNER,1);
   ObjectSet("Balance",OBJPROP_XDISTANCE,20);
   ObjectSet("Balance",OBJPROP_YDISTANCE,90);
   ObjectSetText("Balance","Account Balance : " + comment_balance +" USD",8, "Tahoma", White);
   
   ObjectCreate("Profit_b",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("Profit_b",OBJPROP_CORNER,1);
   ObjectSet("Profit_b",OBJPROP_XDISTANCE,20);
   ObjectSet("Profit_b",OBJPROP_YDISTANCE, 110);
   ObjectSetText("Profit_b","Account Profit : " + comment_profit + " USD" ,8, "Tahoma", White);
   
   ObjectCreate("MaxLotSize",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("MaxLotSize",OBJPROP_CORNER,1);
   ObjectSet("MaxLotSize",OBJPROP_XDISTANCE,20);
   ObjectSet("MaxLotSize",OBJPROP_YDISTANCE, 130);
   ObjectSetText("MaxLotSize", "Max Lot Size : " + comment_max_lot_size ,8, "Tahoma", Red);
   
   ObjectCreate("MaxLoss",OBJ_LABEL,0,0,0,0,0);
   ObjectSet("MaxLoss",OBJPROP_CORNER,1);
   ObjectSet("MaxLoss",OBJPROP_XDISTANCE,20);
   ObjectSet("MaxLoss",OBJPROP_YDISTANCE, 150);
   ObjectSetText("MaxLoss", "Max Loss : " + comment_max_loss + " USD" ,8, "Tahoma", Red);
}

double roundDown (double number, int digit) {
   return(MathFloor(number*MathPow(10, digit)) / MathPow(10, digit));
}

bool checkSpread() {
   return MarketInfo(Symbol(), MODE_SPREAD) < 30;
}

bool openOrder(int orderType, double lotSize, double price, double takeProfit) {
   if(checkSpread()) {
      bool result = OrderSend(Symbol(), orderType, lotSize, price, Slippage, 0, takeProfit, "", Magic, 0, clrNONE);
      return result; 
   }
   return false;
}

int countOrder(int orderType) {
   int count = 0;
   for (int i= OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false) break;
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic ) {
            if(OrderType() == orderType) {
               count++;
            }
         }
   }
   return count;
}

bool getSignalFromMACD() {
   double main = iMACD(Symbol(), PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   double signal = iMACD(Symbol(), PERIOD_M30, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
   
   if(main > 0 && signal > 0) {
      return true;
   } else {
      return false;
   }
}

int getSignalFromRSI() {
   double RSI = 0.0;
   int iShift = iBarShift(Symbol(), PERIOD_M30, Time[0], false);
   RSI = iRSI(Symbol(), 0, 14, PRICE_CLOSE, iShift);
   
   // Buy Condition
   if ( RSI >= 70 ) {
      return -1;
   }
   // Sell Condition
   if (RSI <= 30) {
      return 1;
   }
   
   return 0;
}

double currentOrder(int orderType) {
   int i = 0;
   for(i = OrdersTotal() - 1; i >= 0; i--)
   {
      int x = OrderSelect( i, SELECT_BY_POS, MODE_TRADES );     
      if(Symbol() == OrderSymbol() && OrderMagicNumber() == Magic) {
         if(OrderType() == orderType) {
            return(OrderOpenPrice());
            break;
         }
      }        
   }
   return(0);
}

double getNextPrice(int count) {
   double next = PipStep;
   for(int i = 0; i < count; i++) {
      next += (PipStep);
   }
   return(next);
}

double calculateProfit(int orderType, int count) {
   double profit = 0;
   int ticket = OrdersTotal();
   
   for(int i = ticket - 1; i >= 0; i--) {
      int x = OrderSelect( i, SELECT_BY_POS, MODE_TRADES );     
      if(Symbol() == OrderSymbol() && OrderMagicNumber() == Magic) {
         if(OrderType() == orderType) {
            profit += OrderOpenPrice();
         }
      }
   }
   
   if(count == 0) {
      return profit;
   }
   
   return(profit/count);
}

void modifyTakeProfitOrders(int orderType, double takeProfit) {
   for(int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) {
          break;
      }
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic) {
         if(OrderType() == orderType) {
            bool res = OrderModify(OrderTicket(), OrderOpenPrice(), NULL, takeProfit, NULL, clrNONE);
            Sleep(500);
         }
      }
   }
}

double getLotSize(int count) {
   double lots = Lots;
  
   for(int i = 0; i < count; i++) {
      lots *= LotExponent;
   }
   
   return roundDown(lots, 2);
}

void closeBuyOrder() {
   maxProfit = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      int tmp = OrderSelect(i, SELECT_BY_POS);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_BUY) {
         bool res = OrderClose(OrderTicket(), OrderLots(), bidPrice, Slippage, clrNONE );          
      }
      Sleep(500);
   }
}

void closeSellOrder() {
   maxProfit = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      int tmp = OrderSelect(i, SELECT_BY_POS);
      if(OrderSymbol()==Symbol() && OrderMagicNumber() == Magic && OrderType() == OP_SELL) {
         bool res = OrderClose(OrderTicket(), OrderLots(), askPrice, Slippage, clrNONE );          
      }
      Sleep(500);
   }
}

void OnTick() {
   askPrice = MarketInfo(Symbol(), MODE_ASK);
   bidPrice = MarketInfo(Symbol(), MODE_BID);

   setComment();
   
   bool macd = getSignalFromMACD();
   int rsi = getSignalFromRSI();
   
   double balance = AccountBalance();
   double profit = AccountProfit();
   
   if(profit < maxLoss) {
      maxLoss = profit;
   }
   
   if(profit > 0 && maxProfit < profit) {
      maxProfit = profit;
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 25) /Lots) && profit > 0) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 12.5) /Lots) && profit > 0 && OrdersTotal() > 2 ) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 6.25) /Lots) && profit > 0 && OrdersTotal() > 3 ) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 3.125) /Lots) && profit > 0 && OrdersTotal() > 4 ) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 1.5625) /Lots) && profit > 0 && OrdersTotal() > 5 ) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(maxProfit - profit >= ((getLotSize(OrdersTotal()) * 0.78125) /Lots) && profit > 0 && OrdersTotal() > 6 ) {
      if(countOrder(OP_BUY) > 0 && (macd && rsi != -1 )) {
         closeBuyOrder();
      }
      if(countOrder(OP_SELL) > 0 && (!macd && rsi != 1 )) {
         closeSellOrder();
      }
   }
   
   if(macd && rsi == 1 && countOrder(OP_BUY) == 0 && OrdersTotal() == 0) {
      bool order = openOrder(OP_BUY, Lots, askPrice, 0);
   } else {
      double iopen = iOpen(Symbol(), PERIOD_CURRENT, 0);
      double lotSize = getLotSize(countOrder(OP_BUY));
      
      if(iopen < currentOrder(OP_BUY) - getNextPrice(countOrder(OP_BUY)) * Point && askPrice < currentOrder(OP_BUY) - getNextPrice(countOrder(OP_BUY)) * Point && countOrder(OP_BUY) > 0) {
         double takeProfit = calculateProfit(OP_BUY, countOrder(OP_BUY));
         if(takeProfit > 0 ) {
            bool order = openOrder(OP_BUY, lotSize, askPrice, 0);      
         }
                  
         if(lotSize > maxLotSize) {
            maxLotSize = lotSize;
         }
      }
      if(iopen > currentOrder(OP_BUY) + getNextPrice(countOrder(OP_BUY)) * Point && askPrice > currentOrder(OP_BUY) + getNextPrice(countOrder(OP_BUY)) * Point && countOrder(OP_BUY) > 0) {
         double takeProfit = calculateProfit(OP_BUY, countOrder(OP_BUY));
         if(takeProfit > 0 ) {
            bool order = openOrder(OP_BUY, lotSize, askPrice, 0);      
         }
                  
         if(lotSize > maxLotSize) {
            maxLotSize = lotSize;
         }
      }
   }
   
   if(!macd && rsi == -1 && countOrder(OP_SELL) == 0 && OrdersTotal() == 0) {
      bool order = openOrder(OP_SELL, Lots, bidPrice, 0);
   } else {
      double iopen = iOpen(Symbol(), PERIOD_CURRENT, 0);
      double lotSize = getLotSize(countOrder(OP_SELL));
      
      if(iopen > currentOrder(OP_SELL) + getNextPrice(countOrder(OP_SELL)) * Point && bidPrice > currentOrder(OP_SELL) + getNextPrice(countOrder(OP_SELL)) * Point && countOrder(OP_SELL) > 0) {      
         double takeProfit = calculateProfit(OP_SELL, countOrder(OP_SELL));
         
         if(takeProfit > 0) {
            bool order = openOrder(OP_SELL, lotSize, bidPrice, 0);
         }
         
         if(lotSize > maxLotSize) {
            maxLotSize = lotSize;
         }
      }
      if(iopen < currentOrder(OP_SELL) - getNextPrice(countOrder(OP_SELL)) * Point && bidPrice < currentOrder(OP_SELL) - getNextPrice(countOrder(OP_SELL)) * Point && countOrder(OP_SELL) > 0) {      
         double takeProfit = calculateProfit(OP_SELL, countOrder(OP_SELL));
         if(takeProfit > 0) {
            bool order = openOrder(OP_SELL, lotSize, bidPrice, 0);
         }
         
         if(lotSize > maxLotSize) {
            maxLotSize = lotSize;
         }
      }
   }
}
