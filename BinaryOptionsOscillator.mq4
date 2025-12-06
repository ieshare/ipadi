//+------------------------------------------------------------------+
//|                                      BinaryOptionsOscillator.mq4 |
//|                              Sub-window Oscillator for BO Signal |
//|                                             Stochastic + RSI     |
//+------------------------------------------------------------------+
#property copyright "Binary Options Oscillator"
#property link      ""
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_minimum 0
#property indicator_maximum 100

#property indicator_level1 80
#property indicator_level2 50
#property indicator_level3 20
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DOT

#property indicator_color1 clrYellow       // Stochastic Main
#property indicator_color2 clrWhite        // Stochastic Signal
#property indicator_color3 clrMagenta      // RSI
#property indicator_color4 clrDodgerBlue   // Buy Signal Histogram
#property indicator_color5 clrRed          // Sell Signal Histogram

#property indicator_width1 2
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 3
#property indicator_width5 3

//--- Input parameters
input string     Separator1 = "=== Stochastic Settings ===";
input int        Stoch_K = 14;                       // Stochastic K Period
input int        Stoch_D = 3;                        // Stochastic D Period
input int        Stoch_Slowing = 3;                  // Stochastic Slowing
input int        Stoch_Overbought = 80;              // Stochastic Overbought
input int        Stoch_Oversold = 20;                // Stochastic Oversold

input string     Separator2 = "=== RSI Settings ===";
input int        RSI_Period = 14;                    // RSI Period
input int        RSI_Overbought = 70;                // RSI Overbought
input int        RSI_Oversold = 30;                  // RSI Oversold
input bool       Show_RSI = true;                    // Show RSI Line

input string     Separator3 = "=== Signal Settings ===";
input bool       Show_Signal_Histogram = true;       // Show Signal Histogram
input int        Signal_Threshold = 5;               // Signal Strength Threshold

//--- Indicator buffers
double StochMainBuffer[];
double StochSignalBuffer[];
double RSIBuffer[];
double BuyHistogramBuffer[];
double SellHistogramBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set indicator buffers
   SetIndexBuffer(0, StochMainBuffer);
   SetIndexBuffer(1, StochSignalBuffer);
   SetIndexBuffer(2, RSIBuffer);
   SetIndexBuffer(3, BuyHistogramBuffer);
   SetIndexBuffer(4, SellHistogramBuffer);

   //--- Set styles
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2, clrYellow);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 1, clrWhite);

   if(Show_RSI)
      SetIndexStyle(2, DRAW_LINE, STYLE_DOT, 1, clrMagenta);
   else
      SetIndexStyle(2, DRAW_NONE);

   if(Show_Signal_Histogram)
   {
      SetIndexStyle(3, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrDodgerBlue);
      SetIndexStyle(4, DRAW_HISTOGRAM, STYLE_SOLID, 3, clrRed);
   }
   else
   {
      SetIndexStyle(3, DRAW_NONE);
      SetIndexStyle(4, DRAW_NONE);
   }

   //--- Set labels
   SetIndexLabel(0, "Stochastic %K");
   SetIndexLabel(1, "Stochastic %D");
   SetIndexLabel(2, "RSI");
   SetIndexLabel(3, "Buy Signal");
   SetIndexLabel(4, "Sell Signal");

   //--- Set indicator name
   IndicatorShortName("BO Oscillator (" + IntegerToString(Stoch_K) + "," +
                      IntegerToString(Stoch_D) + "," + IntegerToString(Stoch_Slowing) + ")");

   return(INIT_SUCCEEDED);
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
   if(rates_total < MathMax(Stoch_K + Stoch_D + Stoch_Slowing, RSI_Period) + 10)
      return(0);

   //--- Calculate starting point
   if(prev_calculated == 0)
   {
      limit = rates_total - MathMax(Stoch_K + Stoch_D + Stoch_Slowing, RSI_Period) - 10;

      //--- Initialize buffers
      ArrayInitialize(BuyHistogramBuffer, EMPTY_VALUE);
      ArrayInitialize(SellHistogramBuffer, EMPTY_VALUE);
   }
   else
   {
      limit = rates_total - prev_calculated + 1;
   }

   //--- Main calculation loop
   for(int i = limit; i >= 0; i--)
   {
      //--- Calculate Stochastic
      StochMainBuffer[i] = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_MAIN, i);
      StochSignalBuffer[i] = iStochastic(NULL, 0, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, 0, MODE_SIGNAL, i);

      //--- Calculate RSI
      RSIBuffer[i] = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, i);

      //--- Initialize histogram buffers
      BuyHistogramBuffer[i] = EMPTY_VALUE;
      SellHistogramBuffer[i] = EMPTY_VALUE;

      //--- Skip current bar for signals
      if(i == 0) continue;

      //--- Calculate signal strength
      int signal = GetSignalStrength(i);

      if(Show_Signal_Histogram)
      {
         if(signal >= Signal_Threshold)
         {
            BuyHistogramBuffer[i] = 10;  // Show at bottom
         }
         else if(signal <= -Signal_Threshold)
         {
            SellHistogramBuffer[i] = 90;  // Show at top
         }
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate signal strength                                         |
//+------------------------------------------------------------------+
int GetSignalStrength(int shift)
{
   int strength = 0;

   double stoch_main = StochMainBuffer[shift];
   double stoch_signal = StochSignalBuffer[shift];
   double stoch_main_prev = StochMainBuffer[shift + 1];
   double stoch_signal_prev = StochSignalBuffer[shift + 1];

   double rsi = RSIBuffer[shift];
   double rsi_prev = RSIBuffer[shift + 1];

   //--- Stochastic conditions
   // Oversold bounce
   if(stoch_main < Stoch_Oversold && stoch_main > stoch_main_prev)
      strength += 2;

   // Overbought reversal
   if(stoch_main > Stoch_Overbought && stoch_main < stoch_main_prev)
      strength -= 2;

   // Bullish cross
   if(stoch_main_prev < stoch_signal_prev && stoch_main > stoch_signal)
      strength += 2;

   // Bearish cross
   if(stoch_main_prev > stoch_signal_prev && stoch_main < stoch_signal)
      strength -= 2;

   // Rising from bottom
   if(stoch_main < 50 && stoch_main > stoch_main_prev)
      strength += 1;

   // Falling from top
   if(stoch_main > 50 && stoch_main < stoch_main_prev)
      strength -= 1;

   //--- RSI conditions
   if(rsi < RSI_Oversold && rsi > rsi_prev)
      strength += 2;

   if(rsi > RSI_Overbought && rsi < rsi_prev)
      strength -= 2;

   if(rsi < 50 && rsi > rsi_prev)
      strength += 1;

   if(rsi > 50 && rsi < rsi_prev)
      strength -= 1;

   return strength;
}
//+------------------------------------------------------------------+
