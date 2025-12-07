//+------------------------------------------------------------------+
//|                              BinaryOptions_ScalpingSignal.mq4    |
//|                        Binary Options Scalping Indicator         |
//|                    Based on Round Number Breakout Strategy       |
//+------------------------------------------------------------------+
#property copyright "Binary Options Scalping Signal"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4

#property indicator_color1 clrLime      // PUT Signal (売りシグナル)
#property indicator_color2 clrRed       // CALL Signal (買いシグナル)
#property indicator_color3 clrAqua      // Bounce Point (反発ポイント)
#property indicator_color4 clrYellow    // Breakout Alert

#property indicator_width1 3
#property indicator_width2 3
#property indicator_width3 2
#property indicator_width4 2

//--- Input Parameters
input int       RoundNumberPips = 50;           // ラウンドナンバー間隔 (pips)
input int       BounceDetectPips = 5;           // 反発検出幅 (pips)
input int       BreakoutConfirmPips = 3;        // ブレイク確認幅 (pips)
input int       MinBounceBars = 2;              // 最小反発バー数
input int       MaxBounceBars = 20;             // 最大反発バー数
input int       SignalExpiry = 1;               // シグナル有効期限 (バー数)
input bool      ShowRoundNumbers = true;        // ラウンドナンバー表示
input color     RoundNumberColor = clrDodgerBlue; // ラウンドナンバー色
input int       RoundNumberStyle = STYLE_DASH;  // ラウンドナンバースタイル
input bool      EnableAlerts = true;            // アラート有効
input bool      EnablePushNotification = false; // プッシュ通知有効
input int       ArrowSize = 2;                  // 矢印サイズ

//--- Indicator Buffers
double PutSignalBuffer[];      // PUT (LOW) シグナル
double CallSignalBuffer[];     // CALL (HIGH) シグナル
double BouncePointBuffer[];    // 反発ポイント
double BreakoutAlertBuffer[];  // ブレイクアウトアラート

//--- Global Variables
double gPoint;
int gDigits;
datetime gLastAlertTime = 0;
string gIndicatorName = "BO_Scalping";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Point calculation for different brokers
   gDigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   if(gDigits == 3 || gDigits == 5)
      gPoint = MarketInfo(Symbol(), MODE_POINT) * 10;
   else
      gPoint = MarketInfo(Symbol(), MODE_POINT);

   //--- Indicator buffers mapping
   SetIndexBuffer(0, PutSignalBuffer);
   SetIndexBuffer(1, CallSignalBuffer);
   SetIndexBuffer(2, BouncePointBuffer);
   SetIndexBuffer(3, BreakoutAlertBuffer);

   //--- Set drawing styles
   SetIndexStyle(0, DRAW_ARROW, EMPTY, ArrowSize);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, ArrowSize);
   SetIndexStyle(2, DRAW_ARROW, EMPTY, 1);
   SetIndexStyle(3, DRAW_ARROW, EMPTY, 1);

   //--- Set arrow codes
   SetIndexArrow(0, 234);  // Down arrow for PUT
   SetIndexArrow(1, 233);  // Up arrow for CALL
   SetIndexArrow(2, 159);  // Circle for bounce
   SetIndexArrow(3, 108);  // Diamond for breakout

   //--- Labels
   SetIndexLabel(0, "PUT Signal (売り)");
   SetIndexLabel(1, "CALL Signal (買い)");
   SetIndexLabel(2, "Bounce Point");
   SetIndexLabel(3, "Breakout Alert");

   //--- Empty value
   SetIndexEmptyValue(0, EMPTY_VALUE);
   SetIndexEmptyValue(1, EMPTY_VALUE);
   SetIndexEmptyValue(2, EMPTY_VALUE);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   //--- Short name
   IndicatorShortName("BO Scalping Signal");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Delete round number lines
   ObjectsDeleteAll(0, gIndicatorName);
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
   if(rates_total < MaxBounceBars + 10)
      return(0);

   int limit;

   if(prev_calculated <= 0)
   {
      limit = rates_total - MaxBounceBars - 10;
      ArrayInitialize(PutSignalBuffer, EMPTY_VALUE);
      ArrayInitialize(CallSignalBuffer, EMPTY_VALUE);
      ArrayInitialize(BouncePointBuffer, EMPTY_VALUE);
      ArrayInitialize(BreakoutAlertBuffer, EMPTY_VALUE);
   }
   else
   {
      limit = rates_total - prev_calculated + 1;
   }

   //--- Draw round numbers
   if(ShowRoundNumbers)
      DrawRoundNumbers();

   //--- Main calculation loop
   for(int i = limit; i >= 1; i--)
   {
      //--- Get nearest round number
      double nearestRoundAbove = GetNearestRoundNumber(high[i], true);
      double nearestRoundBelow = GetNearestRoundNumber(low[i], false);

      //--- Check for PUT signal (売りシグナル) - Bearish breakout
      if(CheckPutSignal(i, high, low, close, open, nearestRoundBelow))
      {
         PutSignalBuffer[i] = high[i] + 10 * gPoint;

         //--- Alert for current bar
         if(i == 1 && EnableAlerts && Time[i] != gLastAlertTime)
         {
            gLastAlertTime = Time[i];
            SendAlert("PUT Signal! ラウンドナンバー下抜け確認");
         }
      }

      //--- Check for CALL signal (買いシグナル) - Bullish breakout
      if(CheckCallSignal(i, high, low, close, open, nearestRoundAbove))
      {
         CallSignalBuffer[i] = low[i] - 10 * gPoint;

         //--- Alert for current bar
         if(i == 1 && EnableAlerts && Time[i] != gLastAlertTime)
         {
            gLastAlertTime = Time[i];
            SendAlert("CALL Signal! ラウンドナンバー上抜け確認");
         }
      }

      //--- Mark bounce points for visual reference
      MarkBouncePoints(i, high, low, nearestRoundAbove, nearestRoundBelow);
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Get nearest round number                                          |
//+------------------------------------------------------------------+
double GetNearestRoundNumber(double price, bool above)
{
   double roundInterval = RoundNumberPips * gPoint;

   if(above)
      return(MathCeil(price / roundInterval) * roundInterval);
   else
      return(MathFloor(price / roundInterval) * roundInterval);
}

//+------------------------------------------------------------------+
//| Check for PUT signal (売りシグナル)                               |
//| Logic: Price bounced off round number, then breaks down           |
//+------------------------------------------------------------------+
bool CheckPutSignal(int shift, const double &high[], const double &low[],
                    const double &close[], const double &open[],
                    double roundNumber)
{
   double bounceZoneUpper = roundNumber + BounceDetectPips * gPoint;
   double bounceZoneLower = roundNumber - BounceDetectPips * gPoint;
   double breakoutLevel = roundNumber - BreakoutConfirmPips * gPoint;

   bool foundBounce = false;
   int bounceBar = -1;

   //--- Step 1: Look for previous bounce at round number (手順1)
   for(int i = shift + MinBounceBars; i <= shift + MaxBounceBars; i++)
   {
      //--- Check if price touched round number and bounced UP
      if(low[i] <= bounceZoneUpper && low[i] >= bounceZoneLower)
      {
         //--- Confirm bounce (next bars went higher)
         if(i > shift + 1 && close[i-1] > low[i] + BounceDetectPips * gPoint)
         {
            foundBounce = true;
            bounceBar = i;
            break;
         }
      }
   }

   if(!foundBounce)
      return(false);

   //--- Step 2: Check current bar for breakout (手順2 - ブレイク直前)
   //--- Price should be approaching round number from above and breaking down

   //--- Confirm bearish momentum
   bool bearishBar = close[shift] < open[shift];
   bool approachingBreakout = low[shift] <= bounceZoneUpper &&
                               low[shift] >= breakoutLevel;

   //--- Check previous bar was still above the round number
   bool previousAbove = low[shift+1] > roundNumber;

   //--- Check for breakout confirmation using tick behavior simulation
   //--- (In real tick chart, we'd see zigzag pattern breaking support)
   bool breakoutConfirmed = close[shift] < roundNumber &&
                            close[shift] < close[shift+1];

   //--- Strong signal: bearish engulfing or strong momentum
   bool strongSignal = (close[shift] < open[shift]) &&
                       (high[shift] - low[shift] > 5 * gPoint);

   if(bearishBar && breakoutConfirmed && (previousAbove || strongSignal))
   {
      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+
//| Check for CALL signal (買いシグナル)                              |
//| Logic: Price bounced off round number, then breaks up             |
//+------------------------------------------------------------------+
bool CheckCallSignal(int shift, const double &high[], const double &low[],
                     const double &close[], const double &open[],
                     double roundNumber)
{
   double bounceZoneUpper = roundNumber + BounceDetectPips * gPoint;
   double bounceZoneLower = roundNumber - BounceDetectPips * gPoint;
   double breakoutLevel = roundNumber + BreakoutConfirmPips * gPoint;

   bool foundBounce = false;
   int bounceBar = -1;

   //--- Step 1: Look for previous bounce at round number (手順1)
   for(int i = shift + MinBounceBars; i <= shift + MaxBounceBars; i++)
   {
      //--- Check if price touched round number and bounced DOWN
      if(high[i] >= bounceZoneLower && high[i] <= bounceZoneUpper)
      {
         //--- Confirm bounce (next bars went lower)
         if(i > shift + 1 && close[i-1] < high[i] - BounceDetectPips * gPoint)
         {
            foundBounce = true;
            bounceBar = i;
            break;
         }
      }
   }

   if(!foundBounce)
      return(false);

   //--- Step 2: Check current bar for breakout (手順2 - ブレイク直前)
   //--- Price should be approaching round number from below and breaking up

   //--- Confirm bullish momentum
   bool bullishBar = close[shift] > open[shift];
   bool approachingBreakout = high[shift] >= bounceZoneLower &&
                               high[shift] <= breakoutLevel;

   //--- Check previous bar was still below the round number
   bool previousBelow = high[shift+1] < roundNumber;

   //--- Check for breakout confirmation
   bool breakoutConfirmed = close[shift] > roundNumber &&
                            close[shift] > close[shift+1];

   //--- Strong signal: bullish engulfing or strong momentum
   bool strongSignal = (close[shift] > open[shift]) &&
                       (high[shift] - low[shift] > 5 * gPoint);

   if(bullishBar && breakoutConfirmed && (previousBelow || strongSignal))
   {
      return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+
//| Mark bounce points for visual reference                           |
//+------------------------------------------------------------------+
void MarkBouncePoints(int shift, const double &high[], const double &low[],
                      double roundAbove, double roundBelow)
{
   double bounceZone = BounceDetectPips * gPoint;

   //--- Check for bounce at resistance (上値での反発)
   if(high[shift] >= roundAbove - bounceZone &&
      high[shift] <= roundAbove + bounceZone)
   {
      if(high[shift] > high[shift+1] && high[shift] > high[shift-1])
      {
         BouncePointBuffer[shift] = high[shift] + 5 * gPoint;
      }
   }

   //--- Check for bounce at support (下値での反発)
   if(low[shift] <= roundBelow + bounceZone &&
      low[shift] >= roundBelow - bounceZone)
   {
      if(low[shift] < low[shift+1] && low[shift] < low[shift-1])
      {
         BouncePointBuffer[shift] = low[shift] - 5 * gPoint;
      }
   }
}

//+------------------------------------------------------------------+
//| Draw round number lines                                           |
//+------------------------------------------------------------------+
void DrawRoundNumbers()
{
   double roundInterval = RoundNumberPips * gPoint;
   double currentPrice = (High[0] + Low[0]) / 2;

   //--- Draw 10 round numbers above and below current price
   double baseRound = MathFloor(currentPrice / roundInterval) * roundInterval;

   for(int i = -10; i <= 10; i++)
   {
      double level = baseRound + i * roundInterval;
      string lineName = gIndicatorName + "_RN_" + DoubleToStr(level, gDigits);

      if(ObjectFind(0, lineName) < 0)
      {
         ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, level);
         ObjectSetInteger(0, lineName, OBJPROP_COLOR, RoundNumberColor);
         ObjectSetInteger(0, lineName, OBJPROP_STYLE, RoundNumberStyle);
         ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
         ObjectSetString(0, lineName, OBJPROP_TOOLTIP,
                         "Round Number: " + DoubleToStr(level, gDigits));
      }
   }
}

//+------------------------------------------------------------------+
//| Send alert notification                                           |
//+------------------------------------------------------------------+
void SendAlert(string message)
{
   string fullMessage = Symbol() + " " + PeriodToString(Period()) + ": " + message;

   Alert(fullMessage);

   if(EnablePushNotification)
      SendNotification(fullMessage);
}

//+------------------------------------------------------------------+
//| Convert period to string                                          |
//+------------------------------------------------------------------+
string PeriodToString(int period)
{
   switch(period)
   {
      case PERIOD_M1:  return("M1");
      case PERIOD_M5:  return("M5");
      case PERIOD_M15: return("M15");
      case PERIOD_M30: return("M30");
      case PERIOD_H1:  return("H1");
      case PERIOD_H4:  return("H4");
      case PERIOD_D1:  return("D1");
      case PERIOD_W1:  return("W1");
      case PERIOD_MN1: return("MN");
      default: return("M" + IntegerToString(period));
   }
}

//+------------------------------------------------------------------+
//| Calculate win rate statistics (optional feature)                  |
//+------------------------------------------------------------------+
void CalculateWinRate(int lookback)
{
   int putWins = 0, putLosses = 0;
   int callWins = 0, callLosses = 0;

   for(int i = 2; i < lookback && i < Bars - 1; i++)
   {
      //--- Check PUT signals
      if(PutSignalBuffer[i] != EMPTY_VALUE)
      {
         //--- Next bar closed lower = win
         if(Close[i-1] < Close[i])
            putWins++;
         else
            putLosses++;
      }

      //--- Check CALL signals
      if(CallSignalBuffer[i] != EMPTY_VALUE)
      {
         //--- Next bar closed higher = win
         if(Close[i-1] > Close[i])
            callWins++;
         else
            callLosses++;
      }
   }

   int totalPut = putWins + putLosses;
   int totalCall = callWins + callLosses;

   double putRate = (totalPut > 0) ? (putWins * 100.0 / totalPut) : 0;
   double callRate = (totalCall > 0) ? (callWins * 100.0 / totalCall) : 0;

   Comment("=== BO Scalping Statistics ===\n",
           "PUT Win Rate: ", DoubleToStr(putRate, 1), "% (", putWins, "/", totalPut, ")\n",
           "CALL Win Rate: ", DoubleToStr(callRate, 1), "% (", callWins, "/", totalCall, ")\n",
           "Lookback: ", lookback, " bars");
}
//+------------------------------------------------------------------+
