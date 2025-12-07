//+------------------------------------------------------------------+
//|                           BinaryOptions_ScalpingUltra.mq4        |
//|               Ultra High Accuracy Binary Options Indicator       |
//|         Based on Round Number Breakout + Multi-Confirmation      |
//+------------------------------------------------------------------+
//|                                                                  |
//| 【戦略概要】                                                      |
//| 1. ラウンドナンバー（キリ番）での反発を確認 (手順1)              |
//| 2. ティックチャートの動きを分析してブレイク直前を検出 (手順2)    |
//| 3. 複数の確認要素で高確率シグナルのみを出力                      |
//| 4. 次足の方向を予測してエントリー (手順3: +3pips目安の動き)      |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Binary Options Scalping Ultra"
#property link      ""
#property version   "3.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 8

//--- Buffer colors
#property indicator_color1 clrMagenta    // Ultra Strong PUT
#property indicator_color2 clrLime       // Ultra Strong CALL
#property indicator_color3 clrOrangeRed  // Strong PUT
#property indicator_color4 clrSpringGreen // Strong CALL
#property indicator_color5 clrGray       // Entry Zone Upper
#property indicator_color6 clrGray       // Entry Zone Lower
#property indicator_color7 clrYellow     // Bounce Detection
#property indicator_color8 clrCyan       // Pending Breakout

#property indicator_width1 5
#property indicator_width2 5
#property indicator_width3 3
#property indicator_width4 3

//=============================================================================
//                           INPUT PARAMETERS
//=============================================================================

input string    _S0_ = "════════ 【基本設定】 ════════";
input int       RoundNumberInterval = 50;       // ラウンドナンバー間隔 (pips)
input bool      IncludeHalfRounds = true;       // .50レベルも含める
input int       MinSignalStrength = 85;         // 最小シグナル強度 (%)

input string    _S1_ = "════════ 【反発検出設定】 ════════";
input int       BounceZonePips = 5;             // 反発ゾーン幅 (pips)
input int       MinBounceCount = 1;             // 最小反発回数
input int       MaxBounceCount = 5;             // 最大反発回数（品質向上）
input int       LookbackBars = 50;              // 反発検索バー数
input int       BounceConfirmBars = 3;          // 反発確認バー数

input string    _S2_ = "════════ 【ブレイク判定設定】 ════════";
input int       BreakoutPips = 3;               // ブレイク判定幅 (pips)
input double    BreakoutRatio = 0.6;            // ブレイクバー実体比率
input bool      RequireCloseBreak = true;       // 終値ブレイク必須

input string    _S3_ = "════════ 【MTF確認設定】 ════════";
input bool      UseMTFConfirm = true;           // MTF確認使用
input ENUM_TIMEFRAMES HigherTF = PERIOD_M5;     // 上位時間足
input int       MTFTrendBars = 5;               // MTFトレンド確認バー数

input string    _S4_ = "════════ 【フィルター設定】 ════════";
input bool      UseTrendFilter = true;          // トレンドフィルター
input int       FastMA = 8;                     // 短期MA
input int       SlowMA = 21;                    // 長期MA
input ENUM_MA_METHOD MAMethod = MODE_EMA;       // MA種類

input bool      UseMomentumFilter = true;       // モメンタムフィルター
input int       RSIPeriod = 14;                 // RSI期間
input int       RSIOverbought = 70;             // RSI買われすぎ
input int       RSIOversold = 30;               // RSI売られすぎ

input bool      UseVolatilityFilter = true;     // ボラティリティフィルター
input int       ATRPeriod = 14;                 // ATR期間
input double    MinATRMultiplier = 0.5;         // 最小ATR倍率
input double    MaxATRMultiplier = 2.0;         // 最大ATR倍率

input bool      UseVolumeFilter = true;         // 出来高フィルター
input double    VolumeMultiplier = 1.2;         // 出来高倍率

input bool      UseTimeFilter = true;           // 時間フィルター
input int       StartHour = 9;                  // 取引開始時間
input int       EndHour = 23;                   // 取引終了時間
input bool      AvoidNewsTime = true;           // 重要時間帯回避

input bool      UseSpreadFilter = true;         // スプレッドフィルター
input int       MaxSpreadPips = 3;              // 最大スプレッド (pips)

input string    _S5_ = "════════ 【ティック分析設定】 ════════";
input bool      UseTickAnalysis = true;         // ティック分析使用
input int       TickMomentumBars = 5;           // モメンタム計算バー
input double    MinTickMomentum = 0.6;          // 最小ティックモメンタム

input string    _S6_ = "════════ 【キャンドルパターン】 ════════";
input bool      UseCandlePatterns = true;       // キャンドルパターン使用
input double    EngulfingRatio = 1.0;           // エンガルフィング比率
input double    PinBarRatio = 2.0;              // ピンバー比率

input string    _S7_ = "════════ 【表示設定】 ════════";
input bool      ShowRoundLines = true;          // ラウンドナンバー表示
input bool      ShowEntryZone = true;           // エントリーゾーン表示
input bool      ShowBounceMarks = true;         // 反発マーク表示
input color     MainRoundColor = clrDodgerBlue; // メインライン色
input color     HalfRoundColor = clrSlateGray;  // ハーフライン色
input color     EntryZoneColor = clrGold;       // エントリーゾーン色
input int       ArrowSize = 3;                  // 矢印サイズ

input string    _S8_ = "════════ 【アラート設定】 ════════";
input bool      EnableAlert = true;             // アラート有効
input bool      EnableSound = true;             // サウンド有効
input string    AlertSound = "alert.wav";       // アラート音
input bool      EnablePush = false;             // プッシュ通知
input bool      ShowStatistics = true;          // 統計表示

input string    _S9_ = "════════ 【高度な設定】 ════════";
input bool      StrictMode = true;              // 厳格モード（高精度）
input int       ConsecutiveBarsCheck = 3;       // 連続バー確認数
input bool      RequireRetest = false;          // リテスト必須

//=============================================================================
//                           INDICATOR BUFFERS
//=============================================================================
double UltraStrongPutBuffer[];
double UltraStrongCallBuffer[];
double StrongPutBuffer[];
double StrongCallBuffer[];
double EntryZoneUpperBuffer[];
double EntryZoneLowerBuffer[];
double BounceBuffer[];
double PendingBuffer[];

//=============================================================================
//                           GLOBAL VARIABLES
//=============================================================================
double gPoint;
int gDigits;
datetime gLastAlertTime = 0;
string gPrefix = "BOSU_";

// Statistics
int gUltraPutTotal = 0, gUltraPutWin = 0;
int gUltraCallTotal = 0, gUltraCallWin = 0;
int gStrongPutTotal = 0, gStrongPutWin = 0;
int gStrongCallTotal = 0, gStrongCallWin = 0;

// Round number cache
double gRoundLevels[];
int gRoundLevelCount = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   // Point normalization for 3/5 digit brokers
   gDigits = (int)Digits;
   gPoint = (gDigits == 3 || gDigits == 5) ? Point * 10 : Point;

   // Setup buffers
   SetIndexBuffer(0, UltraStrongPutBuffer);
   SetIndexBuffer(1, UltraStrongCallBuffer);
   SetIndexBuffer(2, StrongPutBuffer);
   SetIndexBuffer(3, StrongCallBuffer);
   SetIndexBuffer(4, EntryZoneUpperBuffer);
   SetIndexBuffer(5, EntryZoneLowerBuffer);
   SetIndexBuffer(6, BounceBuffer);
   SetIndexBuffer(7, PendingBuffer);

   // Drawing styles
   SetIndexStyle(0, DRAW_ARROW, EMPTY, ArrowSize + 2);
   SetIndexStyle(1, DRAW_ARROW, EMPTY, ArrowSize + 2);
   SetIndexStyle(2, DRAW_ARROW, EMPTY, ArrowSize);
   SetIndexStyle(3, DRAW_ARROW, EMPTY, ArrowSize);
   SetIndexStyle(4, DRAW_NONE);
   SetIndexStyle(5, DRAW_NONE);
   SetIndexStyle(6, DRAW_ARROW, EMPTY, 1);
   SetIndexStyle(7, DRAW_ARROW, EMPTY, 1);

   // Arrow codes
   SetIndexArrow(0, 234);   // Ultra PUT
   SetIndexArrow(1, 233);   // Ultra CALL
   SetIndexArrow(2, 242);   // Strong PUT
   SetIndexArrow(3, 241);   // Strong CALL
   SetIndexArrow(6, 159);   // Bounce
   SetIndexArrow(7, 115);   // Pending

   // Labels
   SetIndexLabel(0, "ULTRA PUT (最強売り)");
   SetIndexLabel(1, "ULTRA CALL (最強買い)");
   SetIndexLabel(2, "STRONG PUT (強い売り)");
   SetIndexLabel(3, "STRONG CALL (強い買い)");
   SetIndexLabel(4, NULL);
   SetIndexLabel(5, NULL);
   SetIndexLabel(6, "Bounce Detected");
   SetIndexLabel(7, "Breakout Pending");

   // Empty values
   for(int i = 0; i < 8; i++)
      SetIndexEmptyValue(i, EMPTY_VALUE);

   // Initialize round levels array
   ArrayResize(gRoundLevels, 50);

   IndicatorShortName("BO Scalping Ultra v3.0");

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
   if(rates_total < LookbackBars + 100)
      return(0);

   int limit;
   if(prev_calculated <= 0)
   {
      limit = rates_total - LookbackBars - 100;
      InitializeBuffers();
   }
   else
   {
      limit = rates_total - prev_calculated + 2;
   }

   // Update round number levels
   UpdateRoundLevels(close[0]);

   // Draw visual elements
   if(ShowRoundLines)
      DrawRoundNumberLines();

   // Main analysis loop
   for(int i = limit; i >= 1; i--)
   {
      AnalyzeBarComplete(i, time, open, high, low, close, tick_volume, spread);
   }

   // Update win rate statistics
   UpdateStatistics();

   // Display statistics
   if(ShowStatistics)
      DisplayStatistics();

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Initialize all buffers                                            |
//+------------------------------------------------------------------+
void InitializeBuffers()
{
   ArrayInitialize(UltraStrongPutBuffer, EMPTY_VALUE);
   ArrayInitialize(UltraStrongCallBuffer, EMPTY_VALUE);
   ArrayInitialize(StrongPutBuffer, EMPTY_VALUE);
   ArrayInitialize(StrongCallBuffer, EMPTY_VALUE);
   ArrayInitialize(EntryZoneUpperBuffer, EMPTY_VALUE);
   ArrayInitialize(EntryZoneLowerBuffer, EMPTY_VALUE);
   ArrayInitialize(BounceBuffer, EMPTY_VALUE);
   ArrayInitialize(PendingBuffer, EMPTY_VALUE);
}

//+------------------------------------------------------------------+
//| Update round number levels cache                                  |
//+------------------------------------------------------------------+
void UpdateRoundLevels(double currentPrice)
{
   double mainInterval = RoundNumberInterval * gPoint;
   double halfInterval = (RoundNumberInterval / 2.0) * gPoint;

   double basePrice = MathFloor(currentPrice / mainInterval) * mainInterval;
   gRoundLevelCount = 0;

   // Add main round numbers
   for(int i = -10; i <= 10; i++)
   {
      double level = basePrice + i * mainInterval;
      if(gRoundLevelCount < 50)
      {
         gRoundLevels[gRoundLevelCount] = level;
         gRoundLevelCount++;
      }

      // Add half rounds if enabled
      if(IncludeHalfRounds && gRoundLevelCount < 50)
      {
         double halfLevel = level + halfInterval;
         gRoundLevels[gRoundLevelCount] = halfLevel;
         gRoundLevelCount++;
      }
   }

   // Sort levels
   ArraySort(gRoundLevels, gRoundLevelCount);
}

//+------------------------------------------------------------------+
//| Find nearest round level                                          |
//+------------------------------------------------------------------+
double FindNearestRoundLevel(double price, bool above)
{
   if(above)
   {
      for(int i = 0; i < gRoundLevelCount; i++)
      {
         if(gRoundLevels[i] > price)
            return(gRoundLevels[i]);
      }
   }
   else
   {
      for(int i = gRoundLevelCount - 1; i >= 0; i--)
      {
         if(gRoundLevels[i] < price)
            return(gRoundLevels[i]);
      }
   }
   return(0);
}

//+------------------------------------------------------------------+
//| Complete bar analysis with all confirmations                      |
//+------------------------------------------------------------------+
void AnalyzeBarComplete(int shift, const datetime &time[],
                        const double &open[], const double &high[],
                        const double &low[], const double &close[],
                        const long &tick_volume[], const int &spread[])
{
   //=== Pre-filters (quick rejection) ===
   if(!PassPreFilters(shift, time, spread))
      return;

   //=== Find relevant round levels ===
   double nearestAbove = FindNearestRoundLevel(high[shift], true);
   double nearestBelow = FindNearestRoundLevel(low[shift], false);

   //=== Calculate PUT signal score ===
   double putScore = CalculatePutScore(shift, open, high, low, close, tick_volume, nearestBelow);

   //=== Calculate CALL signal score ===
   double callScore = CalculateCallScore(shift, open, high, low, close, tick_volume, nearestAbove);

   //=== Generate signals based on score ===
   double offset = (high[shift] - low[shift]) * 0.5 + 10 * gPoint;

   if(putScore >= 95)
   {
      UltraStrongPutBuffer[shift] = high[shift] + offset;
      TriggerAlert(shift, "ULTRA PUT", putScore, time[shift]);
   }
   else if(putScore >= MinSignalStrength)
   {
      StrongPutBuffer[shift] = high[shift] + offset * 0.7;
      if(putScore >= 90)
         TriggerAlert(shift, "STRONG PUT", putScore, time[shift]);
   }

   if(callScore >= 95)
   {
      UltraStrongCallBuffer[shift] = low[shift] - offset;
      TriggerAlert(shift, "ULTRA CALL", callScore, time[shift]);
   }
   else if(callScore >= MinSignalStrength)
   {
      StrongCallBuffer[shift] = low[shift] - offset * 0.7;
      if(callScore >= 90)
         TriggerAlert(shift, "STRONG CALL", callScore, time[shift]);
   }

   //=== Mark bounce and pending signals for visual reference ===
   if(ShowBounceMarks)
      MarkBounceSignals(shift, high, low, nearestAbove, nearestBelow);
}

//+------------------------------------------------------------------+
//| Pre-filters for quick rejection                                   |
//+------------------------------------------------------------------+
bool PassPreFilters(int shift, const datetime &time[], const int &spread[])
{
   //--- Time filter
   if(UseTimeFilter)
   {
      MqlDateTime dt;
      TimeToStruct(time[shift], dt);

      if(dt.hour < StartHour || dt.hour >= EndHour)
         return(false);

      // Avoid high volatility times (news)
      if(AvoidNewsTime)
      {
         // Skip first minutes of each hour (often news time)
         if(dt.min < 5)
            return(false);

         // Skip around major session opens
         if((dt.hour == 9 || dt.hour == 14 || dt.hour == 16) && dt.min < 15)
            return(false);
      }
   }

   //--- Spread filter
   if(UseSpreadFilter)
   {
      double currentSpread = (spread[shift] * Point) / gPoint;
      if(currentSpread > MaxSpreadPips)
         return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+
//| Calculate PUT signal score (0-100)                                |
//+------------------------------------------------------------------+
double CalculatePutScore(int shift, const double &open[], const double &high[],
                         const double &low[], const double &close[],
                         const long &tick_volume[], double roundLevel)
{
   if(roundLevel == 0)
      return(0);

   double score = 0;
   double bounceZone = BounceZonePips * gPoint;
   double breakZone = BreakoutPips * gPoint;

   //====================================
   // STEP 1: Bounce Detection (手順1)
   // Price must have bounced at the round number previously
   //====================================
   int bounceCount = 0;
   int bounceQuality = 0;
   bool hasValidBounce = false;

   for(int i = shift + BounceConfirmBars; i <= shift + LookbackBars; i++)
   {
      // Check if low touched round number zone (support test)
      if(low[i] >= roundLevel - bounceZone && low[i] <= roundLevel + bounceZone)
      {
         // Confirm bounce: subsequent bars went higher
         bool bounceConfirmed = true;
         for(int j = 1; j < BounceConfirmBars && (i - j) > shift; j++)
         {
            if(close[i-j] <= low[i])
            {
               bounceConfirmed = false;
               break;
            }
         }

         if(bounceConfirmed)
         {
            bounceCount++;
            hasValidBounce = true;

            // Quality: How strong was the bounce?
            double bounceSize = (high[i-1] - low[i]) / gPoint;
            if(bounceSize > 10)
               bounceQuality += 5;
         }

         if(bounceCount >= MaxBounceCount)
            break;
      }
   }

   if(!hasValidBounce || bounceCount < MinBounceCount)
      return(0);

   // Base score for valid setup
   score += 25;
   score += MathMin(bounceCount * 3, 10);
   score += MathMin(bounceQuality, 10);

   //====================================
   // STEP 2: Breakout Detection (手順2)
   // Price approaching breakout - "ブレイク直前"
   //====================================
   bool isBearish = close[shift] < open[shift];
   bool atLevel = low[shift] <= roundLevel + bounceZone;
   bool breaking = close[shift] < roundLevel;
   bool previousAbove = close[shift + 1] > roundLevel || low[shift + 1] > roundLevel;

   if(!isBearish || !atLevel)
      return(0);

   if(breaking && previousAbove)
   {
      score += 30; // Breakout confirmed

      // Check breakout strength
      double breakSize = (roundLevel - close[shift]) / gPoint;
      if(breakSize >= BreakoutPips)
         score += 5;

      // Check if close at level is required
      if(RequireCloseBreak && close[shift] >= roundLevel)
         return(0);
   }
   else
   {
      // Not quite breaking yet - might be pending
      if(atLevel && previousAbove)
      {
         PendingBuffer[shift] = low[shift] - 5 * gPoint;
      }
      return(0);
   }

   //====================================
   // STEP 3: Body/Wick Analysis
   // Simulate tick chart behavior
   //====================================
   double body = MathAbs(close[shift] - open[shift]);
   double range = high[shift] - low[shift];
   double bodyRatio = (range > 0) ? body / range : 0;

   if(bodyRatio >= BreakoutRatio)
      score += 5;

   // Close position (should be near low for PUT)
   if(range > 0)
   {
      double closePos = (high[shift] - close[shift]) / range;
      if(closePos > 0.7)
         score += 5;
   }

   //====================================
   // STEP 4: Apply Filters
   //====================================

   //--- Trend Filter (MA)
   if(UseTrendFilter)
   {
      double fastMA = iMA(Symbol(), 0, FastMA, 0, MAMethod, PRICE_CLOSE, shift);
      double slowMA = iMA(Symbol(), 0, SlowMA, 0, MAMethod, PRICE_CLOSE, shift);

      if(close[shift] < fastMA && fastMA < slowMA)
         score += 8; // Aligned with downtrend
      else if(close[shift] < fastMA)
         score += 4; // Partial alignment
   }

   //--- Momentum Filter (RSI)
   if(UseMomentumFilter)
   {
      double rsi = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, shift);

      if(rsi < 50)
         score += 4; // Bearish momentum

      if(rsi < RSIOversold)
         score -= 5; // Too oversold, might bounce

      if(rsi > RSIOverbought)
         score += 5; // Overbought, good for PUT
   }

   //--- Volatility Filter (ATR)
   if(UseVolatilityFilter)
   {
      double atr = iATR(Symbol(), 0, ATRPeriod, shift);
      double avgATR = 0;
      for(int i = shift; i < shift + 20; i++)
         avgATR += iATR(Symbol(), 0, ATRPeriod, i);
      avgATR /= 20;

      double atrRatio = (avgATR > 0) ? atr / avgATR : 1;

      if(atrRatio >= MinATRMultiplier && atrRatio <= MaxATRMultiplier)
         score += 5; // Good volatility range
   }

   //--- Volume Filter
   if(UseVolumeFilter)
   {
      long avgVolume = 0;
      for(int i = shift; i < shift + 20; i++)
         avgVolume += tick_volume[i];
      avgVolume /= 20;

      if(tick_volume[shift] > avgVolume * VolumeMultiplier)
         score += 5; // High volume on signal
   }

   //--- Tick Analysis (simulate tick chart)
   if(UseTickAnalysis)
   {
      int tickScore = AnalyzeTickMomentum(shift, open, high, low, close, tick_volume, false);
      score += tickScore;
   }

   //--- Candle Pattern Analysis
   if(UseCandlePatterns)
   {
      int patternScore = AnalyzeBearishPatterns(shift, open, high, low, close);
      score += patternScore;
   }

   //--- MTF Confirmation
   if(UseMTFConfirm)
   {
      int mtfScore = CheckMTFConfirmation(shift, false);
      score += mtfScore;
   }

   //--- Consecutive Bars Check (strict mode)
   if(StrictMode)
   {
      int bearishCount = 0;
      for(int i = shift; i < shift + ConsecutiveBarsCheck; i++)
      {
         if(close[i] < open[i])
            bearishCount++;
      }

      if(bearishCount >= ConsecutiveBarsCheck - 1)
         score += 5;
   }

   return(MathMin(score, 100));
}

//+------------------------------------------------------------------+
//| Calculate CALL signal score (0-100)                               |
//+------------------------------------------------------------------+
double CalculateCallScore(int shift, const double &open[], const double &high[],
                          const double &low[], const double &close[],
                          const long &tick_volume[], double roundLevel)
{
   if(roundLevel == 0)
      return(0);

   double score = 0;
   double bounceZone = BounceZonePips * gPoint;
   double breakZone = BreakoutPips * gPoint;

   //====================================
   // STEP 1: Bounce Detection
   //====================================
   int bounceCount = 0;
   int bounceQuality = 0;
   bool hasValidBounce = false;

   for(int i = shift + BounceConfirmBars; i <= shift + LookbackBars; i++)
   {
      if(high[i] >= roundLevel - bounceZone && high[i] <= roundLevel + bounceZone)
      {
         bool bounceConfirmed = true;
         for(int j = 1; j < BounceConfirmBars && (i - j) > shift; j++)
         {
            if(close[i-j] >= high[i])
            {
               bounceConfirmed = false;
               break;
            }
         }

         if(bounceConfirmed)
         {
            bounceCount++;
            hasValidBounce = true;
            double bounceSize = (high[i] - low[i-1]) / gPoint;
            if(bounceSize > 10)
               bounceQuality += 5;
         }

         if(bounceCount >= MaxBounceCount)
            break;
      }
   }

   if(!hasValidBounce || bounceCount < MinBounceCount)
      return(0);

   score += 25;
   score += MathMin(bounceCount * 3, 10);
   score += MathMin(bounceQuality, 10);

   //====================================
   // STEP 2: Breakout Detection
   //====================================
   bool isBullish = close[shift] > open[shift];
   bool atLevel = high[shift] >= roundLevel - bounceZone;
   bool breaking = close[shift] > roundLevel;
   bool previousBelow = close[shift + 1] < roundLevel || high[shift + 1] < roundLevel;

   if(!isBullish || !atLevel)
      return(0);

   if(breaking && previousBelow)
   {
      score += 30;
      double breakSize = (close[shift] - roundLevel) / gPoint;
      if(breakSize >= BreakoutPips)
         score += 5;

      if(RequireCloseBreak && close[shift] <= roundLevel)
         return(0);
   }
   else
   {
      if(atLevel && previousBelow)
         PendingBuffer[shift] = high[shift] + 5 * gPoint;
      return(0);
   }

   //====================================
   // STEP 3: Body/Wick Analysis
   //====================================
   double body = MathAbs(close[shift] - open[shift]);
   double range = high[shift] - low[shift];
   double bodyRatio = (range > 0) ? body / range : 0;

   if(bodyRatio >= BreakoutRatio)
      score += 5;

   if(range > 0)
   {
      double closePos = (close[shift] - low[shift]) / range;
      if(closePos > 0.7)
         score += 5;
   }

   //====================================
   // STEP 4: Apply Filters
   //====================================
   if(UseTrendFilter)
   {
      double fastMA = iMA(Symbol(), 0, FastMA, 0, MAMethod, PRICE_CLOSE, shift);
      double slowMA = iMA(Symbol(), 0, SlowMA, 0, MAMethod, PRICE_CLOSE, shift);

      if(close[shift] > fastMA && fastMA > slowMA)
         score += 8;
      else if(close[shift] > fastMA)
         score += 4;
   }

   if(UseMomentumFilter)
   {
      double rsi = iRSI(Symbol(), 0, RSIPeriod, PRICE_CLOSE, shift);

      if(rsi > 50)
         score += 4;

      if(rsi > RSIOverbought)
         score -= 5;

      if(rsi < RSIOversold)
         score += 5;
   }

   if(UseVolatilityFilter)
   {
      double atr = iATR(Symbol(), 0, ATRPeriod, shift);
      double avgATR = 0;
      for(int i = shift; i < shift + 20; i++)
         avgATR += iATR(Symbol(), 0, ATRPeriod, i);
      avgATR /= 20;

      double atrRatio = (avgATR > 0) ? atr / avgATR : 1;

      if(atrRatio >= MinATRMultiplier && atrRatio <= MaxATRMultiplier)
         score += 5;
   }

   if(UseVolumeFilter)
   {
      long avgVolume = 0;
      for(int i = shift; i < shift + 20; i++)
         avgVolume += tick_volume[i];
      avgVolume /= 20;

      if(tick_volume[shift] > avgVolume * VolumeMultiplier)
         score += 5;
   }

   if(UseTickAnalysis)
   {
      int tickScore = AnalyzeTickMomentum(shift, open, high, low, close, tick_volume, true);
      score += tickScore;
   }

   if(UseCandlePatterns)
   {
      int patternScore = AnalyzeBullishPatterns(shift, open, high, low, close);
      score += patternScore;
   }

   if(UseMTFConfirm)
   {
      int mtfScore = CheckMTFConfirmation(shift, true);
      score += mtfScore;
   }

   if(StrictMode)
   {
      int bullishCount = 0;
      for(int i = shift; i < shift + ConsecutiveBarsCheck; i++)
      {
         if(close[i] > open[i])
            bullishCount++;
      }

      if(bullishCount >= ConsecutiveBarsCheck - 1)
         score += 5;
   }

   return(MathMin(score, 100));
}

//+------------------------------------------------------------------+
//| Analyze tick momentum (simulate tick chart from bars)             |
//+------------------------------------------------------------------+
int AnalyzeTickMomentum(int shift, const double &open[], const double &high[],
                        const double &low[], const double &close[],
                        const long &tick_volume[], bool bullish)
{
   int score = 0;

   // Calculate momentum over recent bars
   double momentum = 0;
   for(int i = shift; i < shift + TickMomentumBars; i++)
   {
      momentum += close[i] - open[i];
   }

   double avgRange = 0;
   for(int i = shift; i < shift + TickMomentumBars; i++)
   {
      avgRange += high[i] - low[i];
   }
   avgRange /= TickMomentumBars;

   double momentumRatio = (avgRange > 0) ? MathAbs(momentum) / (avgRange * TickMomentumBars) : 0;

   if(bullish && momentum > 0 && momentumRatio >= MinTickMomentum)
      score += 10;
   else if(!bullish && momentum < 0 && momentumRatio >= MinTickMomentum)
      score += 10;

   // Volume confirmation
   if(tick_volume[shift] > tick_volume[shift + 1])
      score += 3;

   return(score);
}

//+------------------------------------------------------------------+
//| Analyze bearish candle patterns                                   |
//+------------------------------------------------------------------+
int AnalyzeBearishPatterns(int shift, const double &open[], const double &high[],
                           const double &low[], const double &close[])
{
   int score = 0;

   double body = MathAbs(close[shift] - open[shift]);
   double prevBody = MathAbs(close[shift+1] - open[shift+1]);
   double upperWick = high[shift] - MathMax(open[shift], close[shift]);
   double lowerWick = MathMin(open[shift], close[shift]) - low[shift];
   double range = high[shift] - low[shift];

   // Bearish engulfing
   if(close[shift] < open[shift] && close[shift+1] > open[shift+1])
   {
      if(body > prevBody * EngulfingRatio)
         score += 8;
   }

   // Shooting star (bearish pin bar at top)
   if(upperWick > body * PinBarRatio && lowerWick < body * 0.5)
      score += 6;

   // Strong bearish bar
   if(range > 0 && body / range > 0.7)
      score += 4;

   return(MathMin(score, 15));
}

//+------------------------------------------------------------------+
//| Analyze bullish candle patterns                                   |
//+------------------------------------------------------------------+
int AnalyzeBullishPatterns(int shift, const double &open[], const double &high[],
                           const double &low[], const double &close[])
{
   int score = 0;

   double body = MathAbs(close[shift] - open[shift]);
   double prevBody = MathAbs(close[shift+1] - open[shift+1]);
   double upperWick = high[shift] - MathMax(open[shift], close[shift]);
   double lowerWick = MathMin(open[shift], close[shift]) - low[shift];
   double range = high[shift] - low[shift];

   // Bullish engulfing
   if(close[shift] > open[shift] && close[shift+1] < open[shift+1])
   {
      if(body > prevBody * EngulfingRatio)
         score += 8;
   }

   // Hammer (bullish pin bar at bottom)
   if(lowerWick > body * PinBarRatio && upperWick < body * 0.5)
      score += 6;

   // Strong bullish bar
   if(range > 0 && body / range > 0.7)
      score += 4;

   return(MathMin(score, 15));
}

//+------------------------------------------------------------------+
//| Check MTF (Multi-Timeframe) confirmation                          |
//+------------------------------------------------------------------+
int CheckMTFConfirmation(int shift, bool bullish)
{
   int score = 0;

   // Get higher timeframe data
   double htfClose0 = iClose(Symbol(), HigherTF, 0);
   double htfClose1 = iClose(Symbol(), HigherTF, 1);
   double htfMA = iMA(Symbol(), HigherTF, SlowMA, 0, MAMethod, PRICE_CLOSE, 0);

   if(bullish)
   {
      if(htfClose0 > htfClose1)
         score += 4;
      if(htfClose0 > htfMA)
         score += 4;
   }
   else
   {
      if(htfClose0 < htfClose1)
         score += 4;
      if(htfClose0 < htfMA)
         score += 4;
   }

   return(score);
}

//+------------------------------------------------------------------+
//| Mark bounce signals for visual reference                          |
//+------------------------------------------------------------------+
void MarkBounceSignals(int shift, const double &high[], const double &low[],
                       double roundAbove, double roundBelow)
{
   double zone = BounceZonePips * gPoint;

   // Bounce at resistance
   if(high[shift] >= roundAbove - zone && high[shift] <= roundAbove + zone)
   {
      if(high[shift] > high[shift+1] && high[shift] > high[shift-1])
         BounceBuffer[shift] = high[shift] + 5 * gPoint;
   }

   // Bounce at support
   if(low[shift] <= roundBelow + zone && low[shift] >= roundBelow - zone)
   {
      if(low[shift] < low[shift+1] && low[shift] < low[shift-1])
         BounceBuffer[shift] = low[shift] - 5 * gPoint;
   }
}

//+------------------------------------------------------------------+
//| Draw round number horizontal lines                                |
//+------------------------------------------------------------------+
void DrawRoundNumberLines()
{
   double mainInterval = RoundNumberInterval * gPoint;
   double halfInterval = (RoundNumberInterval / 2.0) * gPoint;
   double price = (High[0] + Low[0]) / 2;

   double baseMain = MathFloor(price / mainInterval) * mainInterval;

   for(int i = -5; i <= 5; i++)
   {
      double level = baseMain + i * mainInterval;
      string mainName = gPrefix + "Main_" + DoubleToStr(level, gDigits);

      if(ObjectFind(0, mainName) < 0)
      {
         ObjectCreate(0, mainName, OBJ_HLINE, 0, 0, level);
         ObjectSetInteger(0, mainName, OBJPROP_COLOR, MainRoundColor);
         ObjectSetInteger(0, mainName, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, mainName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, mainName, OBJPROP_BACK, true);
         ObjectSetString(0, mainName, OBJPROP_TOOLTIP, "Round: " + DoubleToStr(level, gDigits));
      }

      // Half rounds
      if(IncludeHalfRounds)
      {
         double halfLevel = level + halfInterval;
         string halfName = gPrefix + "Half_" + DoubleToStr(halfLevel, gDigits);

         if(ObjectFind(0, halfName) < 0)
         {
            ObjectCreate(0, halfName, OBJ_HLINE, 0, 0, halfLevel);
            ObjectSetInteger(0, halfName, OBJPROP_COLOR, HalfRoundColor);
            ObjectSetInteger(0, halfName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, halfName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, halfName, OBJPROP_BACK, true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update win rate statistics                                        |
//+------------------------------------------------------------------+
void UpdateStatistics()
{
   // Check results for bars that have next bar data
   for(int i = 3; i < 100; i++)
   {
      // Ultra Strong PUT
      if(UltraStrongPutBuffer[i] != EMPTY_VALUE)
      {
         static datetime lastUltraPut = 0;
         if(Time[i] != lastUltraPut)
         {
            lastUltraPut = Time[i];
            gUltraPutTotal++;
            if(Close[i-1] < Close[i])
               gUltraPutWin++;
         }
      }

      // Ultra Strong CALL
      if(UltraStrongCallBuffer[i] != EMPTY_VALUE)
      {
         static datetime lastUltraCall = 0;
         if(Time[i] != lastUltraCall)
         {
            lastUltraCall = Time[i];
            gUltraCallTotal++;
            if(Close[i-1] > Close[i])
               gUltraCallWin++;
         }
      }

      // Strong PUT
      if(StrongPutBuffer[i] != EMPTY_VALUE)
      {
         static datetime lastStrongPut = 0;
         if(Time[i] != lastStrongPut)
         {
            lastStrongPut = Time[i];
            gStrongPutTotal++;
            if(Close[i-1] < Close[i])
               gStrongPutWin++;
         }
      }

      // Strong CALL
      if(StrongCallBuffer[i] != EMPTY_VALUE)
      {
         static datetime lastStrongCall = 0;
         if(Time[i] != lastStrongCall)
         {
            lastStrongCall = Time[i];
            gStrongCallTotal++;
            if(Close[i-1] > Close[i])
               gStrongCallWin++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Display statistics on chart                                       |
//+------------------------------------------------------------------+
void DisplayStatistics()
{
   double ultraPutRate = (gUltraPutTotal > 0) ? (gUltraPutWin * 100.0 / gUltraPutTotal) : 0;
   double ultraCallRate = (gUltraCallTotal > 0) ? (gUltraCallWin * 100.0 / gUltraCallTotal) : 0;
   double strongPutRate = (gStrongPutTotal > 0) ? (gStrongPutWin * 100.0 / gStrongPutTotal) : 0;
   double strongCallRate = (gStrongCallTotal > 0) ? (gStrongCallWin * 100.0 / gStrongCallTotal) : 0;

   int totalSignals = gUltraPutTotal + gUltraCallTotal + gStrongPutTotal + gStrongCallTotal;
   int totalWins = gUltraPutWin + gUltraCallWin + gStrongPutWin + gStrongCallWin;
   double totalRate = (totalSignals > 0) ? (totalWins * 100.0 / totalSignals) : 0;

   string sep = "─────────────────────────────────";

   Comment(
      "╔═══════════════════════════════════════╗\n",
      "║    BO SCALPING ULTRA v3.0 STATISTICS  ║\n",
      "╠═══════════════════════════════════════╣\n",
      "║ 【ULTRA シグナル】                    ║\n",
      "║   PUT:  ", StringFormat("%5.1f", ultraPutRate), "% (", gUltraPutWin, "/", gUltraPutTotal, ")            ║\n",
      "║   CALL: ", StringFormat("%5.1f", ultraCallRate), "% (", gUltraCallWin, "/", gUltraCallTotal, ")            ║\n",
      "╠═══════════════════════════════════════╣\n",
      "║ 【STRONG シグナル】                   ║\n",
      "║   PUT:  ", StringFormat("%5.1f", strongPutRate), "% (", gStrongPutWin, "/", gStrongPutTotal, ")            ║\n",
      "║   CALL: ", StringFormat("%5.1f", strongCallRate), "% (", gStrongCallWin, "/", gStrongCallTotal, ")            ║\n",
      "╠═══════════════════════════════════════╣\n",
      "║ 【総合勝率】 ", StringFormat("%5.1f", totalRate), "%                    ║\n",
      "╚═══════════════════════════════════════╝\n",
      "\n",
      "⚠ ULTRAシグナルのみでエントリー推奨\n",
      "⚠ 推奨時間足: M1 または M5\n",
      "⚠ ラウンドナンバー: ", RoundNumberInterval, " pips毎"
   );
}

//+------------------------------------------------------------------+
//| Trigger alert                                                     |
//+------------------------------------------------------------------+
void TriggerAlert(int shift, string type, double strength, datetime barTime)
{
   if(shift != 1)
      return;

   if(barTime == gLastAlertTime)
      return;

   gLastAlertTime = barTime;

   string msg = Symbol() + " " + GetPeriodString() + " | " + type +
                " | Strength: " + DoubleToStr(strength, 0) + "%";

   if(EnableAlert)
      Alert(msg);

   if(EnableSound)
      PlaySound(AlertSound);

   if(EnablePush)
      SendNotification(msg);
}

//+------------------------------------------------------------------+
//| Get period string                                                 |
//+------------------------------------------------------------------+
string GetPeriodString()
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
