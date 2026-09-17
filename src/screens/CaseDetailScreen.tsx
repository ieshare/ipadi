import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { StatusBadge, TypeBadge } from '../components/Badges';
import { DangerButton } from '../components/Form';
import { useCases } from '../context/CasesContext';
import type { RootStackParamList } from '../navigation';
import { amountKindLabel, colors } from '../theme';
import { formatDateJa } from '../utils/dates';
import { confirmAction } from '../utils/dialog';
import { formatYen } from '../utils/format';

export function CaseDetailScreen() {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'CaseDetail'>>();
  const { getCase, deleteCase } = useCases();
  const item = getCase(route.params.id);

  if (!item) {
    return (
      <SafeAreaView style={styles.safe}>
        <Text style={styles.missing}>案件が見つかりません。</Text>
      </SafeAreaView>
    );
  }

  const confirmDelete = () => {
    confirmAction('案件を削除', `${item.clientName} を削除しますか？`, async () => {
      await deleteCase(item.id);
      navigation.navigate('MainTabs', { screen: 'Cases' });
    });
  };

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.badges}>
          <TypeBadge type={item.type} />
          <StatusBadge status={item.status} />
        </View>
        <Text style={styles.client}>{item.clientName}</Text>
        {item.title ? <Text style={styles.title}>{item.title}</Text> : null}

        <View style={styles.amountBox}>
          <Text style={styles.kind}>{amountKindLabel[item.type]}</Text>
          <Text style={styles.amount}>{formatYen(item.amount)}</Text>
        </View>

        <View style={styles.block}>
          <Text style={styles.label}>次アクション</Text>
          <Text style={styles.value}>
            {item.nextAction || '未設定'}
          </Text>
        </View>

        <View style={styles.dates}>
          <View style={styles.dateCard}>
            <Ionicons name="calendar-outline" size={18} color={colors.teal} />
            <Text style={styles.dateLabel}>次回定例日</Text>
            <Text style={styles.dateValue}>
              {formatDateJa(item.nextMeetingDate)}
            </Text>
          </View>
          <View style={styles.dateCard}>
            <Ionicons name="receipt-outline" size={18} color={colors.copper} />
            <Text style={styles.dateLabel}>請求予定日</Text>
            <Text style={styles.dateValue}>
              {formatDateJa(item.invoiceDueDate)}
            </Text>
          </View>
        </View>

        <View style={styles.block}>
          <Text style={styles.label}>メモ</Text>
          <Text style={styles.value}>{item.notes || 'メモはありません。'}</Text>
        </View>

        <Pressable
          style={styles.edit}
          onPress={() => navigation.navigate('CaseForm', { id: item.id })}
        >
          <Text style={styles.editText}>編集する</Text>
        </Pressable>
        <DangerButton label="削除する" onPress={confirmDelete} />
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
    gap: 16,
    paddingBottom: 40,
  },
  missing: {
    margin: 24,
    color: colors.muted,
  },
  badges: {
    flexDirection: 'row',
    gap: 8,
  },
  client: {
    fontSize: 26,
    fontWeight: '800',
    color: colors.ink,
  },
  title: {
    fontSize: 15,
    color: colors.muted,
    marginTop: -8,
  },
  amountBox: {
    backgroundColor: colors.paper,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 16,
  },
  kind: {
    color: colors.muted,
    fontWeight: '700',
    fontSize: 12,
  },
  amount: {
    marginTop: 6,
    fontSize: 28,
    fontWeight: '800',
    color: colors.copper,
  },
  block: {
    backgroundColor: colors.paper,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 16,
    gap: 8,
  },
  label: {
    fontSize: 12,
    fontWeight: '800',
    color: colors.muted,
  },
  value: {
    fontSize: 16,
    color: colors.ink,
    lineHeight: 24,
  },
  dates: {
    flexDirection: 'row',
    gap: 10,
  },
  dateCard: {
    flex: 1,
    backgroundColor: colors.paper,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.line,
    padding: 14,
    gap: 6,
  },
  dateLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.muted,
  },
  dateValue: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.ink,
  },
  edit: {
    backgroundColor: colors.teal,
    borderRadius: 14,
    paddingVertical: 14,
    alignItems: 'center',
  },
  editText: {
    color: colors.white,
    fontWeight: '700',
    fontSize: 16,
  },
});
