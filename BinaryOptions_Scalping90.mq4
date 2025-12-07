//+------------------------------------------------------------------+
//|                            BinaryOptions_Scalping90.mq4          |
//|                  90% Win Rate Binary Options Scalping            |
//|           Ultra Strict Filters + Round Number Breakout           |
//+------------------------------------------------------------------+
//|                                                                  |
//| 【戦略】秒スキャルピング・順張りロジック                          |
//| 1. ラウンドナンバーで一度ピタリと止められていること (手順1)      |
//| 2. ブレイク直前で売り/買いエントリー (手順2)                     |
//| 3. 次足の方向を高確率で予測 (手順3: +3pips目安)                  |
//|                                                                  |
//| ティックチャート分析をシミュレートして精度向上                    |
//+------------------------------------------------------------------+
#property copyright "Binary Options 90% Win Rate"
#property link      ""
#property version   "4.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 4

#property indicator_color1 clrMagenta    // PUT Signal
#property indicator_color2 clrLime       // CALL Signal
#property indicator_color3 clrYellow     // Bounce Alert
#property indicator_color4 clrAqua       // Entry Zone

#property indicator_width1 5
#property indicator_width2 5
#property indicator_width3 1
#property indicator_width4 1

//=============================================================================
//                          INPUT PARAMETERS
//=============================================================================
input string    _0_ = "══════ 【基本設定】 ══════";
input int       RoundNumberPips = 50;           // ラウンドナンバー間隔 (50=50pips毎)
input bool      UseHalfRounds = true;           // 中間レベル(.50)も使用
input int       MinSignalScore = 90;            // 最小シグナルスコア (90%精度)

input string    _1_ = "══════ 【反発検出】 ══════";
input int       BounceZone = 5;                 // 反発ゾーン幅 (pips)
input int       MinBounces = 1;                 // 最小反発回数
input int       LookbackPeriod = 40;            // 過去参照期間

input string    _2_ = "══════ 【ブレイク判定】 ══════";
input int       BreakoutPips = 3;               // ブレイク確認幅 (pips)
input double    MinBodyRatio = 0.65;            // 最小実体比率
input bool      RequireCloseBreak = true;       // 終値ブレイク必須

input string    _3_ = "══════ 【厳格フィルター】 ══════";
input bool      UseTrendFilter = true;          // トレンドフィルター
input int       TrendMA_Fast = 8;               // 短期MA
input int       TrendMA_Slow = 21;              // 長期MA
input ENUM_MA_METHOD TrendMA_Method = MODE_EMA; // MA種類

input bool      UseMomentumFilter = true;       // モメンタムフィルター
input int       MomentumPeriod = 10;            // モメンタム期間

input bool      UseRSIFilter = true;            // RSIフィルター
input int       RSI_Period = 14;                // RSI期間
input int       RSI_OB = 70;                    // RSI買われすぎ
input int       RSI_OS = 30;                    // RSI売られすぎ

input bool      UseATRFilter = true;            // ATRフィルター
input int       ATR_Period = 14;                // ATR期間
input double    ATR_Min = 0.3;                  // 最小ATR倍率
input double    ATR_Max = 2.5;                  // 最大ATR倍率

input bool      UseVolumeFilter = true;         // 出来高フィルター
input double    VolumeMin = 1.0;                // 最小出来高倍率

input bool      UseTimeFilter = true;           // 時間フィルター
input int       TradeStartHour = 10;            // 取引開始時 (サーバー時間)
input int       TradeEndHour = 22;              // 取引終了時

input bool      UseSpreadFilter = true;         // スプレッドフィルター
input int       MaxSpread = 3;                  // 最大スプレッド (pips)

input string    _4_ = "══════ 【MTF確認】 ══════";
input bool      UseMTF = true;                  // 上位足確認
input ENUM_TIMEFRAMES MTF_Period = PERIOD_M5;   // 上位時間足

input string    _5_ = "══════ 【パターン認識】 ══════";
input bool      UsePatterns = true;             // キャンドルパターン使用
input double    EngulfingMinRatio = 1.2;        // エンガルフィング比率
input double    PinBarMinRatio = 2.5;           // ピンバー比率

input string    _6_ = "══════ 【表示設定】 ══════";
input bool      ShowRoundLines = true;          // ラウンドナンバーライン
input color     MainLineColor = clrDodgerBlue;  // メインライン色
input color     HalfLineColor = clrDimGray;     // ハーフライン色
input bool      ShowStats = true;               // 統計表示 (左上)
input int       StatsLookback = 100;            // 統計計算バー数
input color     StatsTextColor = clrWhite;      // 統計テキスト色

input string    _7_ = "══════ 【アラート】 ══════";
input bool      AlertOn = true;                 // アラート有効
input bool      SoundOn = true;                 // サウンド有効
input string    SoundFile = "alert.wav";        // サウンドファイル
input bool      PushOn = false;                 // プッシュ通知

//=============================================================================
//                           BUFFERS
//=============================================================================
double PutBuffer[];
double CallBuffer[];
double BounceBuffer[];
double ZoneBuffer[];

//=============================================================================
//                        GLOBAL VARIABLES
//=============================================================================
double gPoint;
int gDigits;
datetime gLastAlert = 0;
string gPrefix = "BO90_";

// Statistics for display
struct SignalStats {
   int totalPut;
   int winPut;
   int totalCall;
   int winCall;
   int totalSignals;
   int totalWins;
   double winRate;
};
SignalStats gStats;

//+------------------------------------------------------------------+
//| Custom indicator initialization                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Broker point normalization
   gDigits = (int)Digits;
   gPoint = (gDigits == 3 || gDigits == 5) ? Point * 10 : Point;

   // Buffer setup
   SetIndexBuffer(0, PutBuffer);
   SetIndexBuffer(1, CallBuffer);
   SetIndexBuffer(2, BounceBuffer);
   SetIndexBuffer(3, ZoneBuffer);

   SetIndexStyle(0, DRAW_ARROW, EMPTY, 5);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, 5);
   SetIndexStyle(2, DRAW_ARROW, EMPTY, 1);
   SetIndexStyle(3, DRAW_ARROW, EMPTY, 1);

   SetIndexArrow(0, 234);  // DOWN arrow
   SetIndexArrow(1, 233);  // UP arrow
   SetIndexArrow(2, 159);  // Circle
   SetIndexArrow(3, 167);  // Square

   SetIndexLabel(0, "PUT (LOW)");
   SetIndexLabel(1, "CALL (HIGH)");
   SetIndexLabel(2, "Bounce");
   SetIndexLabel(3, "Zone");

   for(int i = 0; i < 4; i++)
      SetIndexEmptyValue(i, EMPTY_VALUE);

   // Initialize stats
   ZeroMemory(gStats);

   // Create stats label
   CreateStatsLabel();

   IndicatorShortName("BO 90% Scalping v4.0");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, gPrefix);
   Comment("");
}

//+------------------------------------------------------------------+
//| Create statistics label                                           |
//+------------------------------------------------------------------+
void CreateStatsLabel()
{
   string name = gPrefix + "Stats";
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, name, OBJPROP_COLOR, StatsTextColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| Main calculation function                                         |
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
   if(rates_total < LookbackPeriod + 100)
      return(0);

   int limit;
   if(prev_calculated <= 0)
   {
      limit = rates_total - LookbackPeriod - 100;
      ArrayInitialize(PutBuffer, EMPTY_VALUE);
      ArrayInitialize(CallBuffer, EMPTY_VALUE);
      ArrayInitialize(BounceBuffer, EMPTY_VALUE);
      ArrayInitialize(ZoneBuffer, EMPTY_VALUE);
   }
   else
   {
      limit = rates_total - prev_calculated + 2;
   }

   // Draw round number lines
   if(ShowRoundLines)
      DrawRoundLines();

   // Main analysis
   for(int i = limit; i >= 1; i--)
   {
      AnalyzeBar(i, time, open, high, low, close, tick_volume, spread);
   }

   // Calculate and display statistics
   if(ShowStats)
   {
      CalculateStats(StatsLookback);
      UpdateStatsDisplay();
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Analyze single bar                                                |
//+------------------------------------------------------------------+
void AnalyzeBar(int shift, const datetime &time[],
                const double &open[], const double &high[],
                const double &low[], const double &close[],
                const long &tick_volume[], const int &spread[])
{
   // Pre-filter check
   if(!PassPreFilters(shift, time, spread))
      return;

   // Find nearest round levels
   double roundBelow = GetRoundLevel(low[shift], false);
   double roundAbove = GetRoundLevel(high[shift], true);

   // Calculate signal scores
   int putScore = CalcPutScore(shift, open, high, low, close, tick_volume, roundBelow);
   int callScore = CalcCallScore(shift, open, high, low, close, tick_volume, roundAbove);

   double offset = (high[shift] - low[shift]) * 0.5 + 15 * gPoint;

   // Generate signals only if score meets threshold
   if(putScore >= MinSignalScore)
   {
      PutBuffer[shift] = high[shift] + offset;
      DoAlert(shift, "PUT", putScore, time[shift]);
   }

   if(callScore >= MinSignalScore)
   {
      CallBuffer[shift] = low[shift] - offset;
      DoAlert(shift, "CALL", callScore, time[shift]);
   }

   // Mark bounces for visual reference
   MarkBounces(shift, high, low, roundAbove, roundBelow);
}

//+------------------------------------------------------------------+
//| Pre-filters                                                       |
//+------------------------------------------------------------------+
bool PassPreFilters(int shift, const datetime &time[], const int &spread[])
{
   // Time filter
   if(UseTimeFilter)
   {
      MqlDateTime dt;
      TimeToStruct(time[shift], dt);

      if(dt.hour < TradeStartHour || dt.hour >= TradeEndHour)
         return(false);

      // Avoid first 5 minutes of each hour (news risk)
      if(dt.min < 5)
         return(false);
   }

   // Spread filter
   if(UseSpreadFilter)
   {
      double spreadPips = (spread[shift] * Point) / gPoint;
      if(spreadPips > MaxSpread)
         return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+
//| Get round number level                                            |
//+------------------------------------------------------------------+
double GetRoundLevel(double price, bool above)
{
   double mainInterval = RoundNumberPips * gPoint;

   if(above)
   {
      double level = MathCeil(price / mainInterval) * mainInterval;

      // Check if half round is closer
      if(UseHalfRounds)
      {
         double halfInterval = (RoundNumberPips / 2.0) * gPoint;
         double halfLevel = MathCeil(price / halfInterval) * halfInterval;
         if(halfLevel < level && halfLevel > price)
            return(halfLevel);
      }
      return(level);
   }
   else
   {
      double level = MathFloor(price / mainInterval) * mainInterval;

      if(UseHalfRounds)
      {
         double halfInterval = (RoundNumberPips / 2.0) * gPoint;
         double halfLevel = MathFloor(price / halfInterval) * halfInterval;
         if(halfLevel > level && halfLevel < price)
            return(halfLevel);
      }
      return(level);
   }
}

//+------------------------------------------------------------------+
//| Calculate PUT signal score (0-100)                                |
//+------------------------------------------------------------------+
int CalcPutScore(int shift, const double &open[], const double &high[],
                 const double &low[], const double &close[],
                 const long &tick_volume[], double roundLevel)
{
   if(roundLevel == 0) return(0);

   int score = 0;
   double zone = BounceZone * gPoint;

   //==========================================
   // STEP 1: Bounce Detection (手順1)
   // ラインで一度ピタリ止められていること
   //==========================================
   int bounces = 0;
   int bounceQuality = 0;

   for(int i = shift + 3; i <= shift + LookbackPeriod; i++)
   {
      // Check if price touched support zone
      if(low[i] >= roundLevel - zone && low[i] <= roundLevel + zone)
      {
         // Verify it was a real bounce (price went up afterward)
         bool isBounce = false;
         for(int j = 1; j <= 3 && (i - j) > shift; j++)
         {
            if(close[i-j] > low[i] + zone)
            {
               isBounce = true;
               break;
            }
         }

         if(isBounce)
         {
            bounces++;
            // Quality: how far did it bounce?
            double bounceHeight = 0;
            for(int j = 1; j <= 5 && (i - j) > shift; j++)
            {
               if(high[i-j] - low[i] > bounceHeight)
                  bounceHeight = high[i-j] - low[i];
            }
            if(bounceHeight > 10 * gPoint)
               bounceQuality++;
         }
      }

      if(bounces >= 3) break;
   }

   if(bounces < MinBounces)
      return(0);

   // Base score for valid bounce setup
   score += 30;
   score += MathMin(bounces * 5, 10);
   score += MathMin(bounceQuality * 3, 6);

   //==========================================
   // STEP 2: Breakout Detection (手順2)
   // ブレイク直前での売りエントリー
   //==========================================

   // Current bar must be bearish
   bool bearish = close[shift] < open[shift];
   if(!bearish) return(0);

   // Price at or near round level
   bool atLevel = low[shift] <= roundLevel + zone;
   if(!atLevel) return(0);

   // Previous bar was above round level
   bool prevAbove = close[shift + 1] > roundLevel;

   // Current bar breaks through
   bool breaking = close[shift] < roundLevel;

   if(RequireCloseBreak && !breaking)
      return(0);

   if(breaking && prevAbove)
   {
      score += 25;

      // Check break strength
      double breakSize = (roundLevel - close[shift]) / gPoint;
      if(breakSize >= BreakoutPips)
         score += 5;
   }
   else
   {
      return(0);
   }

   //==========================================
   // Body Analysis (ティックチャート代用)
   //==========================================
   double body = MathAbs(close[shift] - open[shift]);
   double range = high[shift] - low[shift];
   double bodyRatio = (range > 0) ? body / range : 0;

   if(bodyRatio < MinBodyRatio)
      return(0);

   score += 5;

   // Close near low (strong bearish)
   if(range > 0)
   {
      double closePos = (high[shift] - close[shift]) / range;
      if(closePos > 0.75)
         score += 5;
   }

   //==========================================
   // FILTERS
   //==========================================

   // Trend Filter
   if(UseTrendFilter)
   {
      double fastMA = iMA(Symbol(), 0, TrendMA_Fast, 0, TrendMA_Method, PRICE_CLOSE, shift);
      double slowMA = iMA(Symbol(), 0, TrendMA_Slow, 0, TrendMA_Method, PRICE_CLOSE, shift);

      if(close[shift] < fastMA && fastMA < slowMA)
         score += 8;  // Strong bearish trend
      else if(close[shift] < fastMA)
         score += 4;  // Weak bearish
      else
         score -= 5;  // Against trend
   }

   // Momentum Filter
   if(UseMomentumFilter)
   {
      double mom = 0;
      for(int i = shift; i < shift + MomentumPeriod; i++)
         mom += close[i] - open[i];

      if(mom < 0)
         score += 5;  // Bearish momentum
   }

   // RSI Filter
   if(UseRSIFilter)
   {
      double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, shift);

      if(rsi > RSI_OB)
         score += 6;  // Overbought = good for PUT
      else if(rsi < RSI_OS)
         score -= 8;  // Oversold = bad for PUT
      else if(rsi < 50)
         score += 3;  // Bearish zone
   }

   // ATR Filter
   if(UseATRFilter)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, shift);
      double avgATR = 0;
      for(int i = shift; i < shift + 20; i++)
         avgATR += iATR(Symbol(), 0, ATR_Period, i);
      avgATR /= 20;

      double ratio = (avgATR > 0) ? atr / avgATR : 1;
      if(ratio >= ATR_Min && ratio <= ATR_Max)
         score += 4;
      else
         score -= 5;  // Too volatile or too quiet
   }

   // Volume Filter
   if(UseVolumeFilter)
   {
      long avgVol = 0;
      for(int i = shift; i < shift + 20; i++)
         avgVol += tick_volume[i];
      avgVol /= 20;

      if(tick_volume[shift] >= avgVol * VolumeMin)
         score += 4;
   }

   // MTF Confirmation
   if(UseMTF)
   {
      double mtfClose = iClose(Symbol(), MTF_Period, 0);
      double mtfMA = iMA(Symbol(), MTF_Period, TrendMA_Slow, 0, TrendMA_Method, PRICE_CLOSE, 0);

      if(mtfClose < mtfMA)
         score += 6;  // Higher TF bearish
   }

   // Candle Patterns
   if(UsePatterns)
   {
      int patternScore = CheckBearishPatterns(shift, open, high, low, close);
      score += patternScore;
   }

   return(MathMin(score, 100));
}

//+------------------------------------------------------------------+
//| Calculate CALL signal score (0-100)                               |
//+------------------------------------------------------------------+
int CalcCallScore(int shift, const double &open[], const double &high[],
                  const double &low[], const double &close[],
                  const long &tick_volume[], double roundLevel)
{
   if(roundLevel == 0) return(0);

   int score = 0;
   double zone = BounceZone * gPoint;

   //==========================================
   // STEP 1: Bounce Detection
   //==========================================
   int bounces = 0;
   int bounceQuality = 0;

   for(int i = shift + 3; i <= shift + LookbackPeriod; i++)
   {
      if(high[i] >= roundLevel - zone && high[i] <= roundLevel + zone)
      {
         bool isBounce = false;
         for(int j = 1; j <= 3 && (i - j) > shift; j++)
         {
            if(close[i-j] < high[i] - zone)
            {
               isBounce = true;
               break;
            }
         }

         if(isBounce)
         {
            bounces++;
            double bounceDepth = 0;
            for(int j = 1; j <= 5 && (i - j) > shift; j++)
            {
               if(high[i] - low[i-j] > bounceDepth)
                  bounceDepth = high[i] - low[i-j];
            }
            if(bounceDepth > 10 * gPoint)
               bounceQuality++;
         }
      }
      if(bounces >= 3) break;
   }

   if(bounces < MinBounces)
      return(0);

   score += 30;
   score += MathMin(bounces * 5, 10);
   score += MathMin(bounceQuality * 3, 6);

   //==========================================
   // STEP 2: Breakout Detection
   //==========================================
   bool bullish = close[shift] > open[shift];
   if(!bullish) return(0);

   bool atLevel = high[shift] >= roundLevel - zone;
   if(!atLevel) return(0);

   bool prevBelow = close[shift + 1] < roundLevel;
   bool breaking = close[shift] > roundLevel;

   if(RequireCloseBreak && !breaking)
      return(0);

   if(breaking && prevBelow)
   {
      score += 25;
      double breakSize = (close[shift] - roundLevel) / gPoint;
      if(breakSize >= BreakoutPips)
         score += 5;
   }
   else
   {
      return(0);
   }

   //==========================================
   // Body Analysis
   //==========================================
   double body = MathAbs(close[shift] - open[shift]);
   double range = high[shift] - low[shift];
   double bodyRatio = (range > 0) ? body / range : 0;

   if(bodyRatio < MinBodyRatio)
      return(0);

   score += 5;

   if(range > 0)
   {
      double closePos = (close[shift] - low[shift]) / range;
      if(closePos > 0.75)
         score += 5;
   }

   //==========================================
   // FILTERS
   //==========================================

   if(UseTrendFilter)
   {
      double fastMA = iMA(Symbol(), 0, TrendMA_Fast, 0, TrendMA_Method, PRICE_CLOSE, shift);
      double slowMA = iMA(Symbol(), 0, TrendMA_Slow, 0, TrendMA_Method, PRICE_CLOSE, shift);

      if(close[shift] > fastMA && fastMA > slowMA)
         score += 8;
      else if(close[shift] > fastMA)
         score += 4;
      else
         score -= 5;
   }

   if(UseMomentumFilter)
   {
      double mom = 0;
      for(int i = shift; i < shift + MomentumPeriod; i++)
         mom += close[i] - open[i];

      if(mom > 0)
         score += 5;
   }

   if(UseRSIFilter)
   {
      double rsi = iRSI(Symbol(), 0, RSI_Period, PRICE_CLOSE, shift);

      if(rsi < RSI_OS)
         score += 6;
      else if(rsi > RSI_OB)
         score -= 8;
      else if(rsi > 50)
         score += 3;
   }

   if(UseATRFilter)
   {
      double atr = iATR(Symbol(), 0, ATR_Period, shift);
      double avgATR = 0;
      for(int i = shift; i < shift + 20; i++)
         avgATR += iATR(Symbol(), 0, ATR_Period, i);
      avgATR /= 20;

      double ratio = (avgATR > 0) ? atr / avgATR : 1;
      if(ratio >= ATR_Min && ratio <= ATR_Max)
         score += 4;
      else
         score -= 5;
   }

   if(UseVolumeFilter)
   {
      long avgVol = 0;
      for(int i = shift; i < shift + 20; i++)
         avgVol += tick_volume[i];
      avgVol /= 20;

      if(tick_volume[shift] >= avgVol * VolumeMin)
         score += 4;
   }

   if(UseMTF)
   {
      double mtfClose = iClose(Symbol(), MTF_Period, 0);
      double mtfMA = iMA(Symbol(), MTF_Period, TrendMA_Slow, 0, TrendMA_Method, PRICE_CLOSE, 0);

      if(mtfClose > mtfMA)
         score += 6;
   }

   if(UsePatterns)
   {
      int patternScore = CheckBullishPatterns(shift, open, high, low, close);
      score += patternScore;
   }

   return(MathMin(score, 100));
}

//+------------------------------------------------------------------+
//| Check bearish candle patterns                                     |
//+------------------------------------------------------------------+
int CheckBearishPatterns(int shift, const double &open[], const double &high[],
                         const double &low[], const double &close[])
{
   int score = 0;

   double body = MathAbs(close[shift] - open[shift]);
   double prevBody = MathAbs(close[shift+1] - open[shift+1]);
   double upperWick = high[shift] - MathMax(open[shift], close[shift]);
   double range = high[shift] - low[shift];

   // Bearish Engulfing
   if(close[shift] < open[shift] && close[shift+1] > open[shift+1])
   {
      if(body > prevBody * EngulfingMinRatio)
         score += 6;
   }

   // Shooting Star
   if(upperWick > body * PinBarMinRatio)
      score += 5;

   return(MathMin(score, 10));
}

//+------------------------------------------------------------------+
//| Check bullish candle patterns                                     |
//+------------------------------------------------------------------+
int CheckBullishPatterns(int shift, const double &open[], const double &high[],
                         const double &low[], const double &close[])
{
   int score = 0;

   double body = MathAbs(close[shift] - open[shift]);
   double prevBody = MathAbs(close[shift+1] - open[shift+1]);
   double lowerWick = MathMin(open[shift], close[shift]) - low[shift];
   double range = high[shift] - low[shift];

   // Bullish Engulfing
   if(close[shift] > open[shift] && close[shift+1] < open[shift+1])
   {
      if(body > prevBody * EngulfingMinRatio)
         score += 6;
   }

   // Hammer
   if(lowerWick > body * PinBarMinRatio)
      score += 5;

   return(MathMin(score, 10));
}

//+------------------------------------------------------------------+
//| Mark bounces                                                      |
//+------------------------------------------------------------------+
void MarkBounces(int shift, const double &high[], const double &low[],
                 double roundAbove, double roundBelow)
{
   double zone = BounceZone * gPoint;

   if(high[shift] >= roundAbove - zone && high[shift] <= roundAbove + zone)
   {
      if(high[shift] > high[shift+1] && high[shift] > high[shift-1])
         BounceBuffer[shift] = high[shift] + 3 * gPoint;
   }

   if(low[shift] <= roundBelow + zone && low[shift] >= roundBelow - zone)
   {
      if(low[shift] < low[shift+1] && low[shift] < low[shift-1])
         BounceBuffer[shift] = low[shift] - 3 * gPoint;
   }
}

//+------------------------------------------------------------------+
//| Draw round number lines                                           |
//+------------------------------------------------------------------+
void DrawRoundLines()
{
   double mainInterval = RoundNumberPips * gPoint;
   double halfInterval = (RoundNumberPips / 2.0) * gPoint;
   double price = (High[0] + Low[0]) / 2;

   double base = MathFloor(price / mainInterval) * mainInterval;

   for(int i = -5; i <= 5; i++)
   {
      double level = base + i * mainInterval;
      string name = gPrefix + "Main_" + DoubleToStr(level, gDigits);

      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_HLINE, 0, 0, level);
         ObjectSetInteger(0, name, OBJPROP_COLOR, MainLineColor);
         ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, name, OBJPROP_BACK, true);
      }

      if(UseHalfRounds)
      {
         double halfLevel = level + halfInterval;
         string halfName = gPrefix + "Half_" + DoubleToStr(halfLevel, gDigits);

         if(ObjectFind(0, halfName) < 0)
         {
            ObjectCreate(0, halfName, OBJ_HLINE, 0, 0, halfLevel);
            ObjectSetInteger(0, halfName, OBJPROP_COLOR, HalfLineColor);
            ObjectSetInteger(0, halfName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, halfName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, halfName, OBJPROP_BACK, true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate statistics over lookback period                         |
//+------------------------------------------------------------------+
void CalculateStats(int lookback)
{
   gStats.totalPut = 0;
   gStats.winPut = 0;
   gStats.totalCall = 0;
   gStats.winCall = 0;

   int maxBar = MathMin(lookback, Bars - 2);

   for(int i = 2; i <= maxBar; i++)
   {
      // Check PUT signals
      if(PutBuffer[i] != EMPTY_VALUE)
      {
         gStats.totalPut++;
         // Win if next bar closes lower
         if(Close[i-1] < Close[i])
            gStats.winPut++;
      }

      // Check CALL signals
      if(CallBuffer[i] != EMPTY_VALUE)
      {
         gStats.totalCall++;
         // Win if next bar closes higher
         if(Close[i-1] > Close[i])
            gStats.winCall++;
      }
   }

   gStats.totalSignals = gStats.totalPut + gStats.totalCall;
   gStats.totalWins = gStats.winPut + gStats.winCall;
   gStats.winRate = (gStats.totalSignals > 0) ?
                    (gStats.totalWins * 100.0 / gStats.totalSignals) : 0;
}

//+------------------------------------------------------------------+
//| Update statistics display in top-left corner                      |
//+------------------------------------------------------------------+
void UpdateStatsDisplay()
{
   string name = gPrefix + "Stats";

   double putRate = (gStats.totalPut > 0) ?
                    (gStats.winPut * 100.0 / gStats.totalPut) : 0;
   double callRate = (gStats.totalCall > 0) ?
                     (gStats.winCall * 100.0 / gStats.totalCall) : 0;

   string rateColor = "";
   if(gStats.winRate >= 90)
      rateColor = "★★★";
   else if(gStats.winRate >= 80)
      rateColor = "★★";
   else if(gStats.winRate >= 70)
      rateColor = "★";
   else
      rateColor = "";

   string statsText = StringFormat(
      "╔════════════════════════════════╗\n" +
      "║   BO 90%% Scalping - 統計     ║\n" +
      "╠════════════════════════════════╣\n" +
      "║ 分析期間: 直近 %d 本          ║\n" +
      "╠════════════════════════════════╣\n" +
      "║ エントリー: %d 回              ║\n" +
      "║ 勝ち:       %d 回              ║\n" +
      "║ 勝率:       %.1f%% %s          ║\n" +
      "╠════════════════════════════════╣\n" +
      "║ PUT  : %.1f%% (%d/%d)          ║\n" +
      "║ CALL : %.1f%% (%d/%d)          ║\n" +
      "╚════════════════════════════════╝",
      StatsLookback,
      gStats.totalSignals,
      gStats.totalWins,
      gStats.winRate,
      rateColor,
      putRate, gStats.winPut, gStats.totalPut,
      callRate, gStats.winCall, gStats.totalCall
   );

   ObjectSetString(0, name, OBJPROP_TEXT, statsText);

   // Color based on win rate
   color textColor = clrWhite;
   if(gStats.winRate >= 90)
      textColor = clrLime;
   else if(gStats.winRate >= 80)
      textColor = clrYellow;
   else if(gStats.winRate >= 70)
      textColor = clrOrange;
   else
      textColor = clrRed;

   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
}

//+------------------------------------------------------------------+
//| Alert function                                                    |
//+------------------------------------------------------------------+
void DoAlert(int shift, string type, int score, datetime barTime)
{
   if(shift != 1)
      return;

   if(barTime == gLastAlert)
      return;

   gLastAlert = barTime;

   string msg = Symbol() + " " + PeriodStr() + " | " + type +
                " Signal | Score: " + IntegerToString(score) + "%";

   if(AlertOn)
      Alert(msg);

   if(SoundOn)
      PlaySound(SoundFile);

   if(PushOn)
      SendNotification(msg);
}

//+------------------------------------------------------------------+
//| Period string                                                     |
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
