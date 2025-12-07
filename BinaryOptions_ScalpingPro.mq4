//+------------------------------------------------------------------+
//|                               BinaryOptions_ScalpingPro.mq4      |
//|                    High Accuracy Binary Options Scalping         |
//|           Based on Round Number Breakout + Tick Chart Logic      |
//+------------------------------------------------------------------+
#property copyright "Binary Options Scalping Pro"
#property link      ""
#property version   "2.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 6

#property indicator_color1 clrMagenta    // Strong PUT Signal
#property indicator_color2 clrLime       // Strong CALL Signal
#property indicator_color3 clrOrange     // Weak PUT Signal
#property indicator_color4 clrAqua       // Weak CALL Signal
#property indicator_color5 clrYellow     // Bounce Alert
#property indicator_color6 clrWhite      // Breakout Pending

#property indicator_width1 4
#property indicator_width2 4
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 1
#property indicator_width6 1

//=== Input Parameters ===
input string    S1 = "=== ラウンドナンバー設定 ===";
input int       RoundNumberPips = 50;           // ラウンドナンバー間隔 (pips) [50=50pips毎]
input int       SubRoundPips = 10;              // サブラウンドナンバー (pips) [10=10pips毎]
input bool      UseSubRounds = false;           // サブラウンドナンバーを使用

input string    S2 = "=== シグナル感度設定 ===";
input int       BounceZonePips = 5;             // 反発ゾーン幅 (pips)
input int       BreakoutThreshold = 3;          // ブレイク判定閾値 (pips)
input int       MinBounceCount = 1;             // 最小反発回数
input int       LookbackBars = 30;              // 過去参照バー数

input string    S3 = "=== フィルター設定 ===";
input bool      UseTrendFilter = true;          // トレンドフィルター使用
input int       TrendMAPeriod = 20;             // トレンドMA期間
input ENUM_MA_METHOD TrendMAMethod = MODE_EMA;  // トレンドMA種類
input bool      UseMomentumFilter = true;       // モメンタムフィルター使用
input int       MomentumPeriod = 14;            // モメンタム期間
input int       MomentumThreshold = 100;        // モメンタム閾値

input string    S4 = "=== ティックチャート分析 ===";
input bool      UseTickAnalysis = true;         // ティック分析使用
input int       TickLookback = 50;              // ティック分析本数
input double    TickMomentumMin = 0.5;          // 最小ティックモメンタム

input string    S5 = "=== 表示設定 ===";
input bool      ShowRoundLines = true;          // ラウンドナンバーライン表示
input bool      ShowSubRoundLines = false;      // サブラウンドライン表示
input color     MainRoundColor = clrDodgerBlue; // メインラウンド色
input color     SubRoundColor = clrDimGray;     // サブラウンド色
input int       ArrowOffset = 15;               // 矢印オフセット (pips)

input string    S6 = "=== アラート設定 ===";
input bool      EnableAlert = true;             // アラート有効
input bool      EnableSound = true;             // サウンド有効
input string    SoundFile = "alert.wav";        // サウンドファイル
input bool      EnablePush = false;             // プッシュ通知有効
input bool      ShowStats = true;               // 統計表示

//=== Indicator Buffers ===
double StrongPutBuffer[];
double StrongCallBuffer[];
double WeakPutBuffer[];
double WeakCallBuffer[];
double BounceAlertBuffer[];
double BreakoutPendingBuffer[];

//=== Global Variables ===
double gPoint;
int gDigits;
datetime gLastAlertTime = 0;
string gPrefix = "BOSP_";

//--- Statistics
int gTotalPut = 0, gWinPut = 0;
int gTotalCall = 0, gWinCall = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Point normalization
   gDigits = (int)Digits;
   if(gDigits == 3 || gDigits == 5)
      gPoint = Point * 10;
   else
      gPoint = Point;

   //--- Buffer setup
   SetIndexBuffer(0, StrongPutBuffer);
   SetIndexBuffer(1, StrongCallBuffer);
   SetIndexBuffer(2, WeakPutBuffer);
   SetIndexBuffer(3, WeakCallBuffer);
   SetIndexBuffer(4, BounceAlertBuffer);
   SetIndexBuffer(5, BreakoutPendingBuffer);

   //--- Drawing styles
   SetIndexStyle(0, DRAW_ARROW, EMPTY, 4);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, 4);
   SetIndexStyle(2, DRAW_ARROW, EMPTY, 2);
   SetIndexStyle(3, DRAW_ARROW, EMPTY, 2);
   SetIndexStyle(4, DRAW_ARROW, EMPTY, 1);
   SetIndexStyle(5, DRAW_ARROW, EMPTY, 1);

   //--- Arrow codes
   SetIndexArrow(0, 234);  // Strong PUT - Down arrow
   SetIndexArrow(1, 233);  // Strong CALL - Up arrow
   SetIndexArrow(2, 242);  // Weak PUT - Small down
   SetIndexArrow(3, 241);  // Weak CALL - Small up
   SetIndexArrow(4, 159);  // Bounce - Circle
   SetIndexArrow(5, 115);  // Pending - Diamond

   //--- Labels
   SetIndexLabel(0, "Strong PUT (強い売り)");
   SetIndexLabel(1, "Strong CALL (強い買い)");
   SetIndexLabel(2, "Weak PUT (弱い売り)");
   SetIndexLabel(3, "Weak CALL (弱い買い)");
   SetIndexLabel(4, "Bounce Alert");
   SetIndexLabel(5, "Breakout Pending");

   //--- Empty values
   for(int i = 0; i < 6; i++)
      SetIndexEmptyValue(i, EMPTY_VALUE);

   IndicatorShortName("BO Scalping Pro v2.0");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, gPrefix);
   Comment("");
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
   if(rates_total < LookbackBars + 50)
      return(0);

   int limit;
   if(prev_calculated <= 0)
   {
      limit = rates_total - LookbackBars - 50;
      ArrayInitialize(StrongPutBuffer, EMPTY_VALUE);
      ArrayInitialize(StrongCallBuffer, EMPTY_VALUE);
      ArrayInitialize(WeakPutBuffer, EMPTY_VALUE);
      ArrayInitialize(WeakCallBuffer, EMPTY_VALUE);
      ArrayInitialize(BounceAlertBuffer, EMPTY_VALUE);
      ArrayInitialize(BreakoutPendingBuffer, EMPTY_VALUE);
   }
   else
   {
      limit = rates_total - prev_calculated + 1;
   }

   //--- Draw round number lines
   if(ShowRoundLines)
      DrawRoundNumberLines();

   //--- Main loop
   for(int i = limit; i >= 1; i--)
   {
      AnalyzeBar(i, high, low, close, open, tick_volume);
   }

   //--- Update statistics display
   if(ShowStats)
      UpdateStatsDisplay();

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Analyze single bar for signals                                    |
//+------------------------------------------------------------------+
void AnalyzeBar(int shift, const double &high[], const double &low[],
                const double &close[], const double &open[],
                const long &tick_volume[])
{
   //--- Get relevant round numbers
   double roundAbove = GetRoundNumber(high[shift], true);
   double roundBelow = GetRoundNumber(low[shift], false);

   //--- Calculate signal strength
   int putStrength = CalculatePutSignalStrength(shift, high, low, close, open, tick_volume, roundBelow);
   int callStrength = CalculateCallSignalStrength(shift, high, low, close, open, tick_volume, roundAbove);

   double arrowOffset = ArrowOffset * gPoint;

   //--- Generate signals based on strength
   if(putStrength >= 80)
   {
      StrongPutBuffer[shift] = high[shift] + arrowOffset;
      TriggerAlert(shift, "STRONG PUT", putStrength);
   }
   else if(putStrength >= 60)
   {
      WeakPutBuffer[shift] = high[shift] + arrowOffset * 0.7;
   }

   if(callStrength >= 80)
   {
      StrongCallBuffer[shift] = low[shift] - arrowOffset;
      TriggerAlert(shift, "STRONG CALL", callStrength);
   }
   else if(callStrength >= 60)
   {
      WeakCallBuffer[shift] = low[shift] - arrowOffset * 0.7;
   }

   //--- Mark bounce alerts
   MarkBounces(shift, high, low, roundAbove, roundBelow);

   //--- Update win rate (for bars older than 1)
   if(shift >= 2)
   {
      UpdateWinRate(shift);
   }
}

//+------------------------------------------------------------------+
//| Calculate PUT signal strength (0-100)                             |
//+------------------------------------------------------------------+
int CalculatePutSignalStrength(int shift, const double &high[], const double &low[],
                                const double &close[], const double &open[],
                                const long &tick_volume[], double roundNumber)
{
   int strength = 0;
   double bounceZone = BounceZonePips * gPoint;
   double breakoutZone = BreakoutThreshold * gPoint;

   //=== Step 1: Check for previous bounce at round number (手順1) ===
   int bounceCount = 0;
   int lastBounceBar = -1;

   for(int i = shift + 2; i <= shift + LookbackBars; i++)
   {
      //--- Check if price touched round number zone
      if(low[i] <= roundNumber + bounceZone && low[i] >= roundNumber - bounceZone)
      {
         //--- Confirm it was a bounce (price went up after)
         if(close[i-1] > low[i] + bounceZone)
         {
            bounceCount++;
            if(lastBounceBar < 0)
               lastBounceBar = i;
         }
      }
   }

   //--- Award points for bounces
   if(bounceCount >= MinBounceCount)
   {
      strength += 25;  // Base points for valid setup
      strength += MathMin(bounceCount * 5, 15);  // Extra for multiple bounces
   }
   else
   {
      return(0);  // No valid setup
   }

   //=== Step 2: Check current breakout condition (手順2 - ブレイク直前) ===
   bool bearishBar = close[shift] < open[shift];
   bool priceAtLevel = low[shift] <= roundNumber + bounceZone;
   bool breakingDown = close[shift] < roundNumber;
   bool previousAbove = close[shift + 1] >= roundNumber;

   if(bearishBar && priceAtLevel && breakingDown && previousAbove)
   {
      strength += 30;  // Breakout confirmed

      //--- Check breakout strength
      double breakoutSize = (roundNumber - close[shift]) / gPoint;
      if(breakoutSize >= BreakoutThreshold)
         strength += 10;
   }
   else
   {
      return(0);  // No breakout
   }

   //=== Step 3: Apply filters ===

   //--- Trend filter
   if(UseTrendFilter)
   {
      double ma = iMA(Symbol(), 0, TrendMAPeriod, 0, TrendMAMethod, PRICE_CLOSE, shift);
      if(close[shift] < ma)
         strength += 10;  // Aligned with trend
   }

   //--- Momentum filter
   if(UseMomentumFilter)
   {
      double momentum = iMomentum(Symbol(), 0, MomentumPeriod, PRICE_CLOSE, shift);
      if(momentum < MomentumThreshold)
         strength += 10;  // Bearish momentum
   }

   //--- Tick analysis (simulate tick chart behavior)
   if(UseTickAnalysis)
   {
      int tickScore = AnalyzeTickBehavior(shift, high, low, close, tick_volume, false);
      strength += tickScore;
   }

   //--- Candle pattern analysis
   strength += AnalyzeCandlePattern(shift, high, low, close, open, false);

   return(MathMin(strength, 100));
}

//+------------------------------------------------------------------+
//| Calculate CALL signal strength (0-100)                            |
//+------------------------------------------------------------------+
int CalculateCallSignalStrength(int shift, const double &high[], const double &low[],
                                 const double &close[], const double &open[],
                                 const long &tick_volume[], double roundNumber)
{
   int strength = 0;
   double bounceZone = BounceZonePips * gPoint;
   double breakoutZone = BreakoutThreshold * gPoint;

   //=== Step 1: Check for previous bounce at round number ===
   int bounceCount = 0;
   int lastBounceBar = -1;

   for(int i = shift + 2; i <= shift + LookbackBars; i++)
   {
      if(high[i] >= roundNumber - bounceZone && high[i] <= roundNumber + bounceZone)
      {
         if(close[i-1] < high[i] - bounceZone)
         {
            bounceCount++;
            if(lastBounceBar < 0)
               lastBounceBar = i;
         }
      }
   }

   if(bounceCount >= MinBounceCount)
   {
      strength += 25;
      strength += MathMin(bounceCount * 5, 15);
   }
   else
   {
      return(0);
   }

   //=== Step 2: Check current breakout condition ===
   bool bullishBar = close[shift] > open[shift];
   bool priceAtLevel = high[shift] >= roundNumber - bounceZone;
   bool breakingUp = close[shift] > roundNumber;
   bool previousBelow = close[shift + 1] <= roundNumber;

   if(bullishBar && priceAtLevel && breakingUp && previousBelow)
   {
      strength += 30;

      double breakoutSize = (close[shift] - roundNumber) / gPoint;
      if(breakoutSize >= BreakoutThreshold)
         strength += 10;
   }
   else
   {
      return(0);
   }

   //=== Step 3: Apply filters ===
   if(UseTrendFilter)
   {
      double ma = iMA(Symbol(), 0, TrendMAPeriod, 0, TrendMAMethod, PRICE_CLOSE, shift);
      if(close[shift] > ma)
         strength += 10;
   }

   if(UseMomentumFilter)
   {
      double momentum = iMomentum(Symbol(), 0, MomentumPeriod, PRICE_CLOSE, shift);
      if(momentum > MomentumThreshold)
         strength += 10;
   }

   if(UseTickAnalysis)
   {
      int tickScore = AnalyzeTickBehavior(shift, high, low, close, tick_volume, true);
      strength += tickScore;
   }

   strength += AnalyzeCandlePattern(shift, high, low, close, open, true);

   return(MathMin(strength, 100));
}

//+------------------------------------------------------------------+
//| Analyze tick behavior (simulate tick chart from candle data)      |
//+------------------------------------------------------------------+
int AnalyzeTickBehavior(int shift, const double &high[], const double &low[],
                        const double &close[], const long &tick_volume[], bool bullish)
{
   int score = 0;

   //--- Use tick volume as proxy for activity
   long avgVolume = 0;
   for(int i = shift; i < shift + 10; i++)
      avgVolume += tick_volume[i];
   avgVolume /= 10;

   //--- High volume on breakout bar = stronger signal
   if(tick_volume[shift] > avgVolume * 1.2)
      score += 5;

   //--- Analyze price action momentum (simulate tick chart zigzag)
   double range = high[shift] - low[shift];
   double body = MathAbs(close[shift] - Open[shift]);
   double bodyRatio = (range > 0) ? body / range : 0;

   //--- Strong body = momentum (like tick chart breaking through)
   if(bodyRatio > 0.6)
      score += 5;

   //--- Check if close is near extreme (near high for bull, near low for bear)
   if(bullish)
   {
      double closePosition = (range > 0) ? (close[shift] - low[shift]) / range : 0.5;
      if(closePosition > 0.7)
         score += 5;
   }
   else
   {
      double closePosition = (range > 0) ? (high[shift] - close[shift]) / range : 0.5;
      if(closePosition > 0.7)
         score += 5;
   }

   return(score);
}

//+------------------------------------------------------------------+
//| Analyze candle patterns                                           |
//+------------------------------------------------------------------+
int AnalyzeCandlePattern(int shift, const double &high[], const double &low[],
                         const double &close[], const double &open[], bool bullish)
{
   int score = 0;

   double body = MathAbs(close[shift] - open[shift]);
   double upperWick = high[shift] - MathMax(close[shift], open[shift]);
   double lowerWick = MathMin(close[shift], open[shift]) - low[shift];
   double range = high[shift] - low[shift];

   if(bullish)
   {
      //--- Bullish engulfing
      if(close[shift] > open[shift] &&
         close[shift+1] < open[shift+1] &&
         body > MathAbs(close[shift+1] - open[shift+1]))
         score += 5;

      //--- Bullish pin bar (hammer)
      if(lowerWick > body * 2 && upperWick < body * 0.5)
         score += 5;
   }
   else
   {
      //--- Bearish engulfing
      if(close[shift] < open[shift] &&
         close[shift+1] > open[shift+1] &&
         body > MathAbs(close[shift+1] - open[shift+1]))
         score += 5;

      //--- Bearish pin bar (shooting star)
      if(upperWick > body * 2 && lowerWick < body * 0.5)
         score += 5;
   }

   return(score);
}

//+------------------------------------------------------------------+
//| Get nearest round number                                          |
//+------------------------------------------------------------------+
double GetRoundNumber(double price, bool above)
{
   int pips = UseSubRounds ? SubRoundPips : RoundNumberPips;
   double interval = pips * gPoint;

   if(above)
      return(MathCeil(price / interval) * interval);
   else
      return(MathFloor(price / interval) * interval);
}

//+------------------------------------------------------------------+
//| Mark bounce points                                                |
//+------------------------------------------------------------------+
void MarkBounces(int shift, const double &high[], const double &low[],
                 double roundAbove, double roundBelow)
{
   double zone = BounceZonePips * gPoint;

   //--- Bounce at resistance
   if(high[shift] >= roundAbove - zone && high[shift] <= roundAbove + zone)
   {
      if(shift + 1 < Bars && shift - 1 >= 0)
      {
         if(high[shift] >= high[shift+1] && high[shift] > high[shift-1])
         {
            BounceAlertBuffer[shift] = high[shift] + 5 * gPoint;
         }
      }
   }

   //--- Bounce at support
   if(low[shift] <= roundBelow + zone && low[shift] >= roundBelow - zone)
   {
      if(shift + 1 < Bars && shift - 1 >= 0)
      {
         if(low[shift] <= low[shift+1] && low[shift] < low[shift-1])
         {
            BounceAlertBuffer[shift] = low[shift] - 5 * gPoint;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw round number horizontal lines                                |
//+------------------------------------------------------------------+
void DrawRoundNumberLines()
{
   double mainInterval = RoundNumberPips * gPoint;
   double subInterval = SubRoundPips * gPoint;
   double price = (High[0] + Low[0]) / 2;

   //--- Main round numbers
   double baseMain = MathFloor(price / mainInterval) * mainInterval;
   for(int i = -5; i <= 5; i++)
   {
      double level = baseMain + i * mainInterval;
      string name = gPrefix + "Main_" + DoubleToStr(level, gDigits);

      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, level);
         ObjectSetInteger(0, name, OBJPROP_COLOR, MainRoundColor);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
      }
   }

   //--- Sub round numbers
   if(ShowSubRoundLines && UseSubRounds)
   {
      double baseSub = MathFloor(price / subInterval) * subInterval;
      for(int i = -10; i <= 10; i++)
      {
         double level = baseSub + i * subInterval;
         string name = gPrefix + "Sub_" + DoubleToStr(level, gDigits);

         if(ObjectFind(0, name) < 0)
         {
            ObjectCreate(0, name, OBJ_HLINE, 0, 0, level);
            ObjectSetInteger(0, name, OBJPROP_COLOR, SubRoundColor);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, name, OBJPROP_BACK, true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update win rate statistics                                        |
//+------------------------------------------------------------------+
void UpdateWinRate(int shift)
{
   //--- Check Strong PUT
   if(StrongPutBuffer[shift] != EMPTY_VALUE)
   {
      gTotalPut++;
      if(Close[shift-1] < Close[shift])
         gWinPut++;
   }

   //--- Check Strong CALL
   if(StrongCallBuffer[shift] != EMPTY_VALUE)
   {
      gTotalCall++;
      if(Close[shift-1] > Close[shift])
         gWinCall++;
   }
}

//+------------------------------------------------------------------+
//| Update statistics display                                         |
//+------------------------------------------------------------------+
void UpdateStatsDisplay()
{
   double putRate = (gTotalPut > 0) ? (gWinPut * 100.0 / gTotalPut) : 0;
   double callRate = (gTotalCall > 0) ? (gWinCall * 100.0 / gTotalCall) : 0;
   double totalRate = 0;

   if(gTotalPut + gTotalCall > 0)
      totalRate = ((gWinPut + gWinCall) * 100.0) / (gTotalPut + gTotalCall);

   Comment("╔══════════════════════════════════════╗\n",
           "║   BO Scalping Pro v2.0 Statistics    ║\n",
           "╠══════════════════════════════════════╣\n",
           "║ PUT  Win Rate: ", StringFormat("%5.1f", putRate), "% (", gWinPut, "/", gTotalPut, ")    ║\n",
           "║ CALL Win Rate: ", StringFormat("%5.1f", callRate), "% (", gWinCall, "/", gTotalCall, ")    ║\n",
           "╠══════════════════════════════════════╣\n",
           "║ TOTAL Win Rate: ", StringFormat("%5.1f", totalRate), "%              ║\n",
           "╚══════════════════════════════════════╝\n",
           "\n",
           "強いシグナル(80%+)のみエントリー推奨\n",
           "推奨時間足: M1 または M5");
}

//+------------------------------------------------------------------+
//| Trigger alert                                                     |
//+------------------------------------------------------------------+
void TriggerAlert(int shift, string signalType, int strength)
{
   if(shift != 1)
      return;

   if(Time[shift] == gLastAlertTime)
      return;

   gLastAlertTime = Time[shift];

   string msg = Symbol() + " " + PeriodStr() + " - " + signalType +
                " Signal! Strength: " + IntegerToString(strength) + "%";

   if(EnableAlert)
      Alert(msg);

   if(EnableSound)
      PlaySound(SoundFile);

   if(EnablePush)
      SendNotification(msg);
}

//+------------------------------------------------------------------+
//| Get period string                                                 |
//+------------------------------------------------------------------+
string PeriodStr()
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
      default: return "M" + IntegerToString(Period());
   }
}
//+------------------------------------------------------------------+
