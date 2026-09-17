import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { SelectableChip } from '../components/Badges';
import { CaseCard } from '../components/CaseCard';
import { useCases } from '../context/CasesContext';
import type { RootStackParamList } from '../navigation';
import { colors, statusMeta } from '../theme';
import type { CaseStatus } from '../types';
import { sortCases } from '../utils/format';

const FILTERS: { key: 'all' | CaseStatus; label: string }[] = [
  { key: 'all', label: 'すべて' },
  { key: 'proposal', label: statusMeta.proposal.label },
  { key: 'in_progress', label: statusMeta.in_progress.label },
  { key: 'awaiting_invoice', label: statusMeta.awaiting_invoice.label },
  { key: 'done', label: statusMeta.done.label },
];

export function CaseListScreen() {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { cases, loading } = useCases();
  const [filter, setFilter] = useState<'all' | CaseStatus>('all');

  const visible = useMemo(() => {
    const sorted = sortCases(cases);
    if (filter === 'all') return sorted;
    return sorted.filter((item) => item.status === filter);
  }, [cases, filter]);

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>案件</Text>
          <Text style={styles.sub}>{cases.length}件をローカル保存</Text>
        </View>
        <Pressable
          style={styles.add}
          onPress={() => navigation.navigate('CaseForm', {})}
        >
          <Ionicons name="add" size={22} color={colors.white} />
          <Text style={styles.addText}>追加</Text>
        </Pressable>
      </View>

      <View>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.filters}
        >
          {FILTERS.map((f) => (
            <SelectableChip
              key={f.key}
              label={f.label}
              active={filter === f.key}
              color={colors.ink}
              onPress={() => setFilter(f.key)}
            />
          ))}
        </ScrollView>
      </View>

      {loading ? (
        <ActivityIndicator color={colors.teal} style={{ marginTop: 32 }} />
      ) : (
        <ScrollView style={styles.flex} contentContainerStyle={styles.list}>
          {visible.length === 0 ? (
            <View style={styles.empty}>
              <Text style={styles.emptyTitle}>案件がありません</Text>
              <Text style={styles.emptyBody}>
                右上の「追加」から顧問・短期実装・スポットを登録できます。
              </Text>
            </View>
          ) : (
            visible.map((item) => (
              <CaseCard
                key={item.id}
                item={item}
                onPress={() => navigation.navigate('CaseDetail', { id: item.id })}
              />
            ))
          )}
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  flex: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  title: {
    fontSize: 28,
    fontWeight: '800',
    color: colors.ink,
  },
  sub: {
    marginTop: 4,
    color: colors.muted,
    fontSize: 13,
  },
  add: {
    backgroundColor: colors.teal,
    borderRadius: 999,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  addText: {
    color: colors.white,
    fontWeight: '700',
  },
  filters: {
    paddingHorizontal: 20,
    gap: 8,
    paddingBottom: 12,
  },
  list: {
    paddingHorizontal: 20,
    paddingBottom: 32,
    gap: 12,
  },
  empty: {
    backgroundColor: colors.paper,
    borderRadius: 16,
    padding: 24,
    borderWidth: 1,
    borderColor: colors.line,
    gap: 8,
  },
  emptyTitle: {
    fontWeight: '800',
    fontSize: 16,
    color: colors.ink,
  },
  emptyBody: {
    color: colors.muted,
    lineHeight: 20,
  },
});
