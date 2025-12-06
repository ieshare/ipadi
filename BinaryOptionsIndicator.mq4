//+------------------------------------------------------------------+
//|                                      BinaryOptionsIndicator.mq4  |
//|                                    High Probability BO Indicator |
//|                                             Next Candle Predictor|
//+------------------------------------------------------------------+
#property copyright "Binary Options Indicator"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 8

// Arrow buffers
#property indicator_color1 clrDodgerBlue   // Buy Arrow
#property indicator_color2 clrRed          // Sell Arrow
#property indicator_width1 2
#property indicator_width2 2

// MA buffers
#property indicator_color3 clrYellow       // Fast MA
#property indicator_color4 clrLime         // Medium MA
#property indicator_color5 clrWhite        // Slow MA
#property indicator_color6 clrAqua         // Very Slow MA
#property indicator_width3 1
#property indicator_width4 2
#property indicator_width5 1
#property indicator_width6 1

// Bollinger Bands
#property indicator_color7 clrRed          // Upper Band
#property indicator_color8 clrRed          // Lower Band
#property indicator_width7 1
#property indicator_width8 1

//--- Input parameters
input string     Separator1 = "=== Signal Settings ===";
input int        RSI_Period = 14;                    // RSI Period
input int        RSI_Overbought = 70;                // RSI Overbought Level
input int        RSI_Oversold = 30;                  // RSI Oversold Level
input int        Stoch_K = 14;                       // Stochastic K Period
input int        Stoch_D = 3;                        // Stochastic D Period
input int        Stoch_Slowing = 3;                  // Stochastic Slowing
input int        Stoch_Overbought = 80;              // Stochastic Overbought
input int        Stoch_Oversold = 20;                // Stochastic Oversold

input string     Separator2 = "=== MA Settings ===";
input int        MA_Fast_Period = 5;                 // Fast MA Period
input int        MA_Medium_Period = 10;              // Medium MA Period
input int        MA_Slow_Period = 21;                // Slow MA Period
input int        MA_VerySlow_Period = 50;            // Very Slow MA Period
input ENUM_MA_METHOD MA_Method = MODE_EMA;           // MA Method

input string     Separator3 = "=== Bollinger Bands ===";
input int        BB_Period = 20;                     // BB Period
input double     BB_Deviation = 2.0;                 // BB Deviation

input string     Separator4 = "=== Display Settings ===";
input bool       Show_Arrows = true;                 // Show Signal Arrows
input bool       Show_Statistics = true;             // Show Win Statistics
input bool       Show_Timer = true;                  // Show Countdown Timer
input bool       Show_MAs = true;                    // Show Moving Averages
input bool       Show_BB = true;                     // Show Bollinger Bands
input int        Arrow_Offset = 10;                  // Arrow Offset (Points)
input color      Stats_Color = clrLime;              // Statistics Color
input color      Timer_Color = clrYellow;            // Timer Color
input int        Font_Size = 10;                     // Font Size

input string     Separator5 = "=== Alert Settings ===";
input bool       Alert_On_Signal = false;            // Alert on Signal
input bool       Alert_Sound = false;                // Sound Alert
input bool       Alert_Email = false;                // Email Alert

//--- Indicator buffers
double BuyArrowBuffer[];
double SellArrowBuffer[];
double MAFastBuffer[];
double MAMediumBuffer[];
double MASlowBuffer[];
double MAVerySlowBuffer[];
double BBUpperBuffer[];
double BBLowerBuffer[];

//--- Global variables for statistics
int TotalSignals100 = 0, WinSignals100 = 0;
int TotalSignals200 = 0, WinSignals200 = 0;
int TotalSignals300 = 0, WinSignals300 = 0;
int TotalSignals500 = 0, WinSignals500 = 0;
int TotalSignalsAll = 0, WinSignalsAll = 0;

// Signal history arrays
int SignalDirection[];     // 1 = Buy, -1 = Sell, 0 = None
double SignalPrice[];      // Price at signal
datetime SignalTime[];     // Time of signal
int SignalResult[];        // 1 = Win, -1 = Loss, 0 = Pending

int HistorySize = 10000;
int LastCalculatedBar = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set indicator buffers
   SetIndexBuffer(0, BuyArrowBuffer);
   SetIndexBuffer(1, SellArrowBuffer);
   SetIndexBuffer(2, MAFastBuffer);
   SetIndexBuffer(3, MAMediumBuffer);
   SetIndexBuffer(4, MASlowBuffer);
   SetIndexBuffer(5, MAVerySlowBuffer);
   SetIndexBuffer(6, BBUpperBuffer);
   SetIndexBuffer(7, BBLowerBuffer);

   //--- Set arrow styles
   SetIndexStyle(0, DRAW_ARROW, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexArrow(0, 233);  // Up arrow
   SetIndexStyle(1, DRAW_ARROW, STYLE_SOLID, 2, clrRed);
   SetIndexArrow(1, 234);  // Down arrow

   //--- Set MA styles
   if(Show_MAs)
   {
      SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 1, clrYellow);
      SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2, clrLime);
      SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 1, clrWhite);
      SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 1, clrAqua);
   }
   else
   {
      SetIndexStyle(2, DRAW_NONE);
      SetIndexStyle(3, DRAW_NONE);
      SetIndexStyle(4, DRAW_NONE);
      SetIndexStyle(5, DRAW_NONE);
   }

   //--- Set BB styles
   if(Show_BB)
   {
      SetIndexStyle(6, DRAW_LINE, STYLE_SOLID, 1, clrRed);
      SetIndexStyle(7, DRAW_LINE, STYLE_SOLID, 1, clrRed);
   }
   else
   {
      SetIndexStyle(6, DRAW_NONE);
      SetIndexStyle(7, DRAW_NONE);
   }

   //--- Set labels
   SetIndexLabel(0, "Buy Signal");
   SetIndexLabel(1, "Sell Signal");
   SetIndexLabel(2, "MA Fast");
   SetIndexLabel(3, "MA Medium");
   SetIndexLabel(4, "MA Slow");
   SetIndexLabel(5, "MA Very Slow");
   SetIndexLabel(6, "BB Upper");
   SetIndexLabel(7, "BB Lower");

   //--- Initialize signal history arrays
   ArrayResize(SignalDirection, HistorySize);
   ArrayResize(SignalPrice, HistorySize);
   ArrayResize(SignalTime, HistorySize);
   ArrayResize(SignalResult, HistorySize);
   ArrayInitialize(SignalDirection, 0);
   ArrayInitialize(SignalPrice, 0);
   ArrayInitialize(SignalTime, 0);
   ArrayInitialize(SignalResult, 0);

   //--- Set indicator name
   IndicatorShortName("BO Indicator [" + Symbol() + " " + GetTimeframeStr() + "]");

   //--- Create timer for countdown display
   EventSetTimer(1);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   //--- Delete all objects
   ObjectsDeleteAll(0, "BO_");
   Comment("");
}

//+------------------------------------------------------------------+
//| Timer function for countdown                                      |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(Show_Timer)
   {
      DisplayCountdown();
   }
   DisplayStatistics();
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   int limit;

   //--- Check for minimum bars
   if(rates_total < MathMax(MA_VerySlow_Period, MathMax(BB_Period, RSI_Period)) + 10)
      return(0);

   //--- Calculate starting point
   if(prev_calculated == 0)
   {
      limit = rates_total - MathMax(MA_VerySlow_Period, MathMax(BB_Period, RSI_Period)) - 10;

      //--- Initialize buffers
      ArrayInitialize(BuyArrowBuffer, EMPTY_VALUE);
      ArrayInitialize(SellArrowBuffer, EMPTY_VALUE);
   }
   else
   {
      limit = rates_total - prev_calculated + 1;
   }

   //--- Main calculation loop
   for(int i = limit; i >= 0; i--)
   {
      //--- Calculate Moving Averages
      MAFastBuffer[i] = iMA(NULL, 0, MA_Fast_Period, 0, MA_Method, PRICE_CLOSE, i);
      MAMediumBuffer[i] = iMA(NULL, 0, MA_Medium_Period, 0, MA_Method, PRICE_CLOSE, i);
      MASlowBuffer[i] = iMA(NULL, 0, MA_Slow_Period, 0, MA_Method, PRICE_CLOSE, i);
      MAVerySlowBuffer[i] = iMA(NULL, 0, MA_VerySlow_Period, 0, MA_Method, PRICE_CLOSE, i);

      //--- Calculate Bollinger Bands
      BBUpperBuffer[i] = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_UPPER, i);
      BBLowerBuffer[i] = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_LOWER, i);

      //--- Initialize arrow buffers
      BuyArrowBuffer[i] = EMPTY_VALUE;
      SellArrowBuffer[i] = EMPTY_VALUE;

      //--- Skip current bar for signal (wait for close)
      if(i == 0) continue;

      //--- Check for signals
      if(Show_Arrows)
      {
         int signal = GetSignal(i);

         if(signal == 1)  // Buy signal
         {
            BuyArrowBuffer[i] = Low[i] - Arrow_Offset * Point;
            RecordSignal(i, 1, Close[i], Time[i]);
         }
         else if(signal == -1)  // Sell signal
         {
            SellArrowBuffer[i] = High[i] + Arrow_Offset * Point;
            RecordSignal(i, -1, Close[i], Time[i]);
         }
      }
   }

   //--- Update signal results
   UpdateSignalResults();

   //--- Calculate statistics
   CalculateStatistics(rates_total);

   //--- Display statistics
   if(Show_Statistics)
   {
      DisplayStatistics();
   }

   //--- Display countdown timer
   if(Show_Timer)
   {
      DisplayCountdown();
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Get Signal - Multi-indicator confluence                           |
//+------------------------------------------------------------------+
int GetSignal(int shift)
{
   //--- Get indicator values
   double rsi = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, shift);
   double rsi_prev = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, shift + 1);

   double stoch_main = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, shift);
   double stoch_signal = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, shift);
   double stoch_main_prev = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, shift + 1);
   double stoch_signal_prev = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, shift + 1);

   double close = Close[shift];
   double close_prev = Close[shift + 1];

   double ma_fast = MAFastBuffer[shift];
   double ma_medium = MAMediumBuffer[shift];
   double ma_slow = MASlowBuffer[shift];

   double bb_upper = BBUpperBuffer[shift];
   double bb_lower = BBLowerBuffer[shift];
   double bb_middle = iBands(NULL, 0, BB_Period, BB_Deviation, 0, PRICE_CLOSE, MODE_MAIN, shift);

   //--- Count bullish conditions
   int bullish_score = 0;
   int bearish_score = 0;

   //--- RSI conditions
   if(rsi < RSI_Oversold && rsi > rsi_prev) bullish_score += 2;
   if(rsi > RSI_Overbought && rsi < rsi_prev) bearish_score += 2;
   if(rsi < 50 && rsi > rsi_prev) bullish_score += 1;
   if(rsi > 50 && rsi < rsi_prev) bearish_score += 1;

   //--- Stochastic conditions
   if(stoch_main < Stoch_Oversold && stoch_main > stoch_main_prev) bullish_score += 2;
   if(stoch_main > Stoch_Overbought && stoch_main < stoch_main_prev) bearish_score += 2;
   if(stoch_main_prev < stoch_signal_prev && stoch_main > stoch_signal) bullish_score += 2;  // Bullish cross
   if(stoch_main_prev > stoch_signal_prev && stoch_main < stoch_signal) bearish_score += 2;  // Bearish cross

   //--- MA conditions
   if(close > ma_fast && close > ma_medium) bullish_score += 1;
   if(close < ma_fast && close < ma_medium) bearish_score += 1;
   if(ma_fast > ma_medium && ma_medium > ma_slow) bullish_score += 1;
   if(ma_fast < ma_medium && ma_medium < ma_slow) bearish_score += 1;

   //--- Bollinger Band conditions
   if(close_prev < bb_lower && close > bb_lower) bullish_score += 2;  // Bounce from lower band
   if(close_prev > bb_upper && close < bb_upper) bearish_score += 2;  // Bounce from upper band
   if(close < bb_middle && close > close_prev) bullish_score += 1;
   if(close > bb_middle && close < close_prev) bearish_score += 1;

   //--- Price action conditions
   if(close > Open[shift] && close_prev < Open[shift + 1]) bullish_score += 1;  // Bullish reversal
   if(close < Open[shift] && close_prev > Open[shift + 1]) bearish_score += 1;  // Bearish reversal

   //--- Determine signal based on score threshold
   int threshold = 5;  // Minimum score required for signal

   if(bullish_score >= threshold && bullish_score > bearish_score + 2)
   {
      return 1;  // Buy signal
   }

   if(bearish_score >= threshold && bearish_score > bullish_score + 2)
   {
      return -1;  // Sell signal
   }

   return 0;  // No signal
}

//+------------------------------------------------------------------+
//| Record signal in history array                                    |
//+------------------------------------------------------------------+
void RecordSignal(int shift, int direction, double price, datetime time)
{
   //--- Shift array elements
   for(int i = HistorySize - 1; i > 0; i--)
   {
      SignalDirection[i] = SignalDirection[i-1];
      SignalPrice[i] = SignalPrice[i-1];
      SignalTime[i] = SignalTime[i-1];
      SignalResult[i] = SignalResult[i-1];
   }

   //--- Add new signal at index 0
   SignalDirection[0] = direction;
   SignalPrice[0] = price;
   SignalTime[0] = time;
   SignalResult[0] = 0;  // Pending

   //--- Alert if enabled
   if(Alert_On_Signal && shift == 1)
   {
      string alertMsg = Symbol() + " " + GetTimeframeStr() + " - ";
      alertMsg += (direction == 1) ? "BUY SIGNAL" : "SELL SIGNAL";
      alertMsg += " at " + DoubleToString(price, Digits);

      if(Alert_Sound) Alert(alertMsg);
      if(Alert_Email) SendMail("BO Signal Alert", alertMsg);
   }
}

//+------------------------------------------------------------------+
//| Update signal results based on next candle                        |
//+------------------------------------------------------------------+
void UpdateSignalResults()
{
   for(int i = 0; i < HistorySize; i++)
   {
      if(SignalDirection[i] == 0) continue;
      if(SignalResult[i] != 0) continue;  // Already evaluated
      if(SignalTime[i] == 0) continue;

      //--- Find the bar index for this signal
      int barIndex = iBarShift(NULL, 0, SignalTime[i], true);
      if(barIndex < 0 || barIndex < 1) continue;  // Can't find bar or need at least 1 bar after

      //--- Get next candle close
      double nextClose = Close[barIndex - 1];
      double signalClose = SignalPrice[i];

      //--- Determine win/loss
      if(SignalDirection[i] == 1)  // Buy signal
      {
         SignalResult[i] = (nextClose > signalClose) ? 1 : -1;
      }
      else if(SignalDirection[i] == -1)  // Sell signal
      {
         SignalResult[i] = (nextClose < signalClose) ? 1 : -1;
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate statistics                                              |
//+------------------------------------------------------------------+
void CalculateStatistics(int rates_total)
{
   //--- Reset counters
   TotalSignals100 = 0; WinSignals100 = 0;
   TotalSignals200 = 0; WinSignals200 = 0;
   TotalSignals300 = 0; WinSignals300 = 0;
   TotalSignals500 = 0; WinSignals500 = 0;
   TotalSignalsAll = 0; WinSignalsAll = 0;

   //--- Count signals and wins from buffers
   for(int i = 1; i < rates_total - 1; i++)
   {
      int direction = 0;

      if(BuyArrowBuffer[i] != EMPTY_VALUE) direction = 1;
      else if(SellArrowBuffer[i] != EMPTY_VALUE) direction = -1;

      if(direction == 0) continue;

      //--- Check if win
      double signalClose = Close[i];
      double nextClose = Close[i - 1];
      bool isWin = false;

      if(direction == 1)  // Buy
      {
         isWin = (nextClose > signalClose);
      }
      else  // Sell
      {
         isWin = (nextClose < signalClose);
      }

      //--- Update counters based on bar position
      if(i <= 100)
      {
         TotalSignals100++;
         if(isWin) WinSignals100++;
      }
      if(i <= 200)
      {
         TotalSignals200++;
         if(isWin) WinSignals200++;
      }
      if(i <= 300)
      {
         TotalSignals300++;
         if(isWin) WinSignals300++;
      }
      if(i <= 500)
      {
         TotalSignals500++;
         if(isWin) WinSignals500++;
      }

      TotalSignalsAll++;
      if(isWin) WinSignalsAll++;
   }
}

//+------------------------------------------------------------------+
//| Display statistics on chart                                       |
//+------------------------------------------------------------------+
void DisplayStatistics()
{
   if(!Show_Statistics) return;

   string prefix = "BO_STATS_";
   int x = 10;
   int y = 50;
   int lineHeight = 18;

   //--- Delete old objects
   ObjectsDeleteAll(0, prefix);

   //--- Display symbol and timeframe
   string symbolInfo = Symbol() + ", " + GetTimeframeStr();
   CreateLabel(prefix + "SYMBOL", symbolInfo, x, y, clrWhite, Font_Size + 2);
   y += lineHeight + 5;

   //--- Display statistics
   CreateLabel(prefix + "100", FormatStats(100, WinSignals100, TotalSignals100), x, y, GetStatColor(WinSignals100, TotalSignals100), Font_Size);
   y += lineHeight;

   CreateLabel(prefix + "200", FormatStats(200, WinSignals200, TotalSignals200), x, y, GetStatColor(WinSignals200, TotalSignals200), Font_Size);
   y += lineHeight;

   CreateLabel(prefix + "300", FormatStats(300, WinSignals300, TotalSignals300), x, y, GetStatColor(WinSignals300, TotalSignals300), Font_Size);
   y += lineHeight;

   CreateLabel(prefix + "500", FormatStats(500, WinSignals500, TotalSignals500), x, y, GetStatColor(WinSignals500, TotalSignals500), Font_Size);
   y += lineHeight;

   CreateLabel(prefix + "ALL", FormatStatsAll(WinSignalsAll, TotalSignalsAll, Bars), x, y, GetStatColor(WinSignalsAll, TotalSignalsAll), Font_Size);
}

//+------------------------------------------------------------------+
//| Display countdown timer                                           |
//+------------------------------------------------------------------+
void DisplayCountdown()
{
   string prefix = "BO_TIMER_";

   //--- Calculate time remaining until next candle
   int periodSeconds = PeriodSeconds();
   datetime currentTime = TimeCurrent();
   datetime candleOpen = Time[0];
   int elapsed = (int)(currentTime - candleOpen);
   int remaining = periodSeconds - elapsed;

   if(remaining < 0) remaining = 0;

   int minutes = remaining / 60;
   int seconds = remaining % 60;

   string timerText = "あと " + IntegerToString(minutes) + ":" + StringFormat("%02d", seconds);

   //--- Create or update timer label
   string objName = prefix + "COUNTDOWN";

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }

   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, 20);
   ObjectSetString(0, objName, OBJPROP_TEXT, timerText);
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, Font_Size + 4);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, Timer_Color);
}

//+------------------------------------------------------------------+
//| Create label helper function                                      |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}

//+------------------------------------------------------------------+
//| Format statistics string                                          |
//+------------------------------------------------------------------+
string FormatStats(int bars, int wins, int total)
{
   if(total == 0)
      return IntegerToString(bars) + ": Win: 0 / Total: 0 (0.0%)";

   double winRate = (total > 0) ? (double)wins / total * 100.0 : 0;

   return IntegerToString(bars) + ": Win: " + IntegerToString(wins) +
          " / Total: " + IntegerToString(total) +
          " (" + DoubleToString(winRate, 1) + "%)";
}

//+------------------------------------------------------------------+
//| Format statistics string for all bars                             |
//+------------------------------------------------------------------+
string FormatStatsAll(int wins, int total, int bars)
{
   if(total == 0)
      return "All: Win: 0 / Total: 0 (0.0%) [Bars: " + IntegerToString(bars) + "]";

   double winRate = (total > 0) ? (double)wins / total * 100.0 : 0;

   return "All: Win: " + IntegerToString(wins) +
          " / Total: " + IntegerToString(total) +
          " (" + DoubleToString(winRate, 1) + "%) [Bars: " + IntegerToString(bars) + "]";
}

//+------------------------------------------------------------------+
//| Get color based on win rate                                       |
//+------------------------------------------------------------------+
color GetStatColor(int wins, int total)
{
   if(total == 0) return clrGray;

   double winRate = (double)wins / total * 100.0;

   if(winRate >= 75.0) return clrLime;
   if(winRate >= 65.0) return clrGreen;
   if(winRate >= 55.0) return clrYellow;
   if(winRate >= 50.0) return clrOrange;
   return clrRed;
}

//+------------------------------------------------------------------+
//| Get timeframe string                                              |
//+------------------------------------------------------------------+
string GetTimeframeStr()
{
   switch(Period())
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default: return "M" + IntegerToString(Period());
   }
}
//+------------------------------------------------------------------+
