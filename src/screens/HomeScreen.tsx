import { Ionicons } from '@expo/vector-icons';
import { useMemo } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import type { CompositeNavigationProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useNavigation } from '@react-navigation/native';

import { useCases } from '../context/CasesContext';
import type { MainTabParamList, RootStackParamList } from '../navigation';
import { colors } from '../theme';
import type { CaseItem } from '../types';
import {
  formatDateShort,
  formatMonthJa,
  formatTodayJa,
  isThisWeek,
} from '../utils/dates';
import { formatYen, projectedRevenue } from '../utils/format';

type WeekItem = {
  key: string;
  caseId: string;
  date: string;
  kind: 'meeting' | 'invoice';
  clientName: string;
  title: string;
};

function buildWeekItems(cases: CaseItem[]): WeekItem[] {
  const items: WeekItem[] = [];
  for (const c of cases) {
    if (c.status === 'done') continue;
    if (c.nextMeetingDate && isThisWeek(c.nextMeetingDate)) {
      items.push({
        key: `${c.id}-meeting`,
        caseId: c.id,
        date: c.nextMeetingDate,
        kind: 'meeting',
        clientName: c.clientName,
        title: c.nextAction ? c.nextAction : '定例',
      });
    }
    if (c.invoiceDueDate && isThisWeek(c.invoiceDueDate)) {
      items.push({
        key: `${c.id}-invoice`,
        caseId: c.id,
        date: c.invoiceDueDate,
        kind: 'invoice',
        clientName: c.clientName,
        title: c.nextAction || '請求予定',
      });
    }
  }
  return items.sort((a, b) => a.date.localeCompare(b.date));
}

const kindLabel = {
  meeting: '定例',
  invoice: '請求',
} as const;

type HomeNavigation = CompositeNavigationProp<
  BottomTabNavigationProp<MainTabParamList, 'Home'>,
  NativeStackNavigationProp<RootStackParamList>
>;

export function HomeScreen() {
  const navigation = useNavigation<HomeNavigation>();
  const { cases, loading } = useCases();

  const revenue = useMemo(() => projectedRevenue(cases), [cases]);
  const weekItems = useMemo(() => buildWeekItems(cases), [cases]);
  const activeCount = cases.filter(
    (c) => c.status === 'in_progress' || c.status === 'awaiting_invoice',
  ).length;
  const inProgress = cases.filter((c) => c.status === 'in_progress').length;
  const awaiting = cases.filter((c) => c.status === 'awaiting_invoice').length;

  if (loading) {
    return (
      <SafeAreaView style={styles.safe}>
        <ActivityIndicator color={colors.teal} style={{ marginTop: 48 }} />
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.brandRow}>
          <View>
            <Text style={styles.brand}>SoloDesk</Text>
            <Text style={styles.today}>{formatTodayJa()}</Text>
          </View>
          <Text style={styles.tag}>個人エンジニアの机</Text>
        </View>

        <View style={styles.revenueCard}>
          <Text style={styles.revenueKicker}>{formatMonthJa()}の見込み売上</Text>
          <Text style={styles.revenue}>{formatYen(revenue)}</Text>
          <Text style={styles.revenueHint}>
            進行中 {inProgress}件 ／ 請求待ち {awaiting}件の合計
          </Text>
          <Text style={styles.revenueNote}>
            顧問は月額、短期・スポットは見積金額。提案中・完了は含みません。
          </Text>
        </View>

        <View style={styles.sectionHead}>
          <Text style={styles.sectionTitle}>今週の次アクション／請求</Text>
          <Text style={styles.sectionMeta}>{weekItems.length}件</Text>
        </View>

        {weekItems.length === 0 ? (
          <View style={styles.empty}>
            <Text style={styles.emptyText}>今週の予定はありません。</Text>
          </View>
        ) : (
          <View style={styles.list}>
            {weekItems.map((item) => (
              <Pressable
                key={item.key}
                style={styles.weekRow}
                onPress={() =>
                  navigation.navigate('CaseDetail', { id: item.caseId })
                }
              >
                <View
                  style={[
                    styles.kindPill,
                    item.kind === 'invoice' && styles.kindInvoice,
                  ]}
                >
                  <Text style={styles.kindText}>{kindLabel[item.kind]}</Text>
                </View>
                <View style={styles.weekBody}>
                  <Text style={styles.weekClient}>{item.clientName}</Text>
                  <Text style={styles.weekTitle} numberOfLines={2}>
                    {item.title}
                  </Text>
                </View>
                <Text style={styles.weekDate}>{formatDateShort(item.date)}</Text>
              </Pressable>
            ))}
          </View>
        )}

        <Pressable
          style={styles.jump}
          onPress={() => navigation.navigate('Cases')}
        >
          <Ionicons name="briefcase-outline" size={18} color={colors.teal} />
          <Text style={styles.jumpText}>案件一覧を見る（{activeCount}件が売上対象）</Text>
        </Pressable>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  scroll: {
    padding: 20,
    paddingBottom: 40,
    gap: 16,
  },
  brandRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
  },
  brand: {
    fontSize: 28,
    fontWeight: '800',
    color: colors.ink,
    letterSpacing: 0.4,
  },
  today: {
    marginTop: 4,
    color: colors.muted,
    fontSize: 14,
    fontWeight: '600',
  },
  tag: {
    fontSize: 12,
    color: colors.teal,
    fontWeight: '700',
  },
  revenueCard: {
    backgroundColor: colors.teal,
    borderRadius: 20,
    padding: 20,
    gap: 8,
  },
  revenueKicker: {
    color: '#D5EBE6',
    fontSize: 13,
    fontWeight: '700',
  },
  revenue: {
    color: colors.white,
    fontSize: 36,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  revenueHint: {
    color: '#E7F4F1',
    fontSize: 13,
    marginTop: 4,
  },
  revenueNote: {
    color: '#C5DDD8',
    fontSize: 11,
    lineHeight: 16,
  },
  sectionHead: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'baseline',
    marginTop: 8,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.ink,
  },
  sectionMeta: {
    color: colors.muted,
    fontSize: 13,
  },
  list: {
    gap: 10,
  },
  weekRow: {
    backgroundColor: colors.paper,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  kindPill: {
    backgroundColor: colors.tealSoft,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  kindInvoice: {
    backgroundColor: colors.copperSoft,
  },
  kindText: {
    fontSize: 11,
    fontWeight: '800',
    color: colors.ink,
  },
  weekBody: {
    flex: 1,
    gap: 2,
  },
  weekClient: {
    fontWeight: '700',
    color: colors.ink,
    fontSize: 14,
  },
  weekTitle: {
    color: colors.muted,
    fontSize: 13,
  },
  weekDate: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.muted,
  },
  empty: {
    backgroundColor: colors.paper,
    borderRadius: 14,
    padding: 20,
    borderWidth: 1,
    borderColor: colors.line,
  },
  emptyText: {
    color: colors.muted,
  },
  jump: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    alignSelf: 'flex-start',
    marginTop: 4,
  },
  jumpText: {
    color: colors.teal,
    fontWeight: '700',
  },
});
