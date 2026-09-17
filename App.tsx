import { Ionicons } from '@expo/vector-icons';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { StatusBar } from 'expo-status-bar';
import { Platform, StyleSheet, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { CasesProvider } from './src/context/CasesContext';
import type { MainTabParamList, RootStackParamList } from './src/navigation';
import { CaseDetailScreen } from './src/screens/CaseDetailScreen';
import { CaseFormScreen } from './src/screens/CaseFormScreen';
import { CaseListScreen } from './src/screens/CaseListScreen';
import { HomeScreen } from './src/screens/HomeScreen';
import { colors } from './src/theme';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

const navTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: colors.bg,
    card: colors.bg,
    text: colors.ink,
    border: colors.line,
    primary: colors.teal,
  },
};

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.teal,
        tabBarInactiveTintColor: colors.muted,
        tabBarStyle: styles.tabBar,
        tabBarLabelStyle: styles.tabLabel,
      }}
    >
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          title: 'ホーム',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home-outline" size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Cases"
        component={CaseListScreen}
        options={{
          title: '案件',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="briefcase-outline" size={size} color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <CasesProvider>
        <View style={styles.shell}>
          <NavigationContainer theme={navTheme}>
            <StatusBar style="dark" />
            <Stack.Navigator
              screenOptions={{
                headerStyle: { backgroundColor: colors.bg },
                headerTintColor: colors.ink,
                headerTitleStyle: { fontWeight: '700' },
                headerShadowVisible: false,
                contentStyle: { backgroundColor: colors.bg },
              }}
            >
              <Stack.Screen
                name="MainTabs"
                component={MainTabs}
                options={{ headerShown: false }}
              />
              <Stack.Screen
                name="CaseDetail"
                component={CaseDetailScreen}
                options={{ title: '案件詳細' }}
              />
              <Stack.Screen
                name="CaseForm"
                component={CaseFormScreen}
                options={({ route }) => ({
                  title: route.params?.id ? '案件を編集' : '案件を追加',
                })}
              />
            </Stack.Navigator>
          </NavigationContainer>
        </View>
      </CasesProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  shell: {
    flex: 1,
    backgroundColor: colors.bg,
    ...Platform.select({
      web: {
        maxWidth: 480,
        width: '100%',
        alignSelf: 'center',
        minHeight: '100vh' as unknown as number,
        boxShadow: '0 0 48px rgba(27, 36, 32, 0.12)',
      },
    }),
  },
  tabBar: {
    backgroundColor: colors.paper,
    borderTopColor: colors.line,
    height: 64,
    paddingBottom: 8,
    paddingTop: 8,
  },
  tabLabel: {
    fontSize: 11,
    fontWeight: '700',
  },
});
