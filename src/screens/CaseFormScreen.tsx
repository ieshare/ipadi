import { useNavigation, useRoute, type RouteProp } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useMemo, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { SelectableChip } from '../components/Badges';
import { Field, PrimaryButton } from '../components/Form';
import { useCases } from '../context/CasesContext';
import type { RootStackParamList } from '../navigation';
import { colors, statusMeta, typeMeta } from '../theme';
import type { CaseDraft, CaseStatus, CaseType } from '../types';
import { isValidISODate } from '../utils/dates';
import { notify } from '../utils/dialog';

const emptyDraft: CaseDraft = {
  clientName: '',
  title: '',
  type: 'retainer',
  status: 'proposal',
  amount: 0,
  notes: '',
  nextAction: '',
  nextMeetingDate: null,
  invoiceDueDate: null,
};

function normalizeDate(value: string): string | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed;
}

export function CaseFormScreen() {
  const navigation =
    useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<RouteProp<RootStackParamList, 'CaseForm'>>();
  const { getCase, addCase, updateCase } = useCases();
  const editingId = route.params?.id;
  const editing = Boolean(editingId);
  const existing = editingId ? getCase(editingId) : undefined;

  const initial = useMemo<CaseDraft>(() => {
    if (!existing) return emptyDraft;
    return {
      clientName: existing.clientName,
      title: existing.title,
      type: existing.type,
      status: existing.status,
      amount: existing.amount,
      notes: existing.notes,
      nextAction: existing.nextAction,
      nextMeetingDate: existing.nextMeetingDate,
      invoiceDueDate: existing.invoiceDueDate,
    };
  }, [existing]);

  const [clientName, setClientName] = useState(initial.clientName);
  const [title, setTitle] = useState(initial.title);
  const [type, setType] = useState<CaseType>(initial.type);
  const [status, setStatus] = useState<CaseStatus>(initial.status);
  const [amount, setAmount] = useState(
    initial.amount ? String(initial.amount) : '',
  );
  const [notes, setNotes] = useState(initial.notes);
  const [nextAction, setNextAction] = useState(initial.nextAction);
  const [nextMeetingDate, setNextMeetingDate] = useState(
    initial.nextMeetingDate ?? '',
  );
  const [invoiceDueDate, setInvoiceDueDate] = useState(
    initial.invoiceDueDate ?? '',
  );
  const [saving, setSaving] = useState(false);

  const onSave = async () => {
    const name = clientName.trim();
    if (!name) {
      notify('入力エラー', 'クライアント名を入力してください。');
      return;
    }
    const parsedAmount = Number(String(amount).replace(/[¥,，\s]/g, ''));
    if (!Number.isFinite(parsedAmount) || parsedAmount < 0) {
      notify('入力エラー', '金額は0以上の数値で入力してください。');
      return;
    }
    const meeting = normalizeDate(nextMeetingDate);
    const invoice = normalizeDate(invoiceDueDate);
    if (meeting && !isValidISODate(meeting)) {
      notify('入力エラー', '次回定例日は YYYY-MM-DD 形式で入力してください。');
      return;
    }
    if (invoice && !isValidISODate(invoice)) {
      notify('入力エラー', '請求予定日は YYYY-MM-DD 形式で入力してください。');
      return;
    }

    const draft: CaseDraft = {
      clientName: name,
      title: title.trim(),
      type,
      status,
      amount: Math.round(parsedAmount),
      notes: notes.trim(),
      nextAction: nextAction.trim(),
      nextMeetingDate: meeting,
      invoiceDueDate: invoice,
    };

    setSaving(true);
    try {
      if (editing && editingId) {
        await updateCase(editingId, draft);
        navigation.goBack();
      } else {
        const created = await addCase(draft);
        navigation.replace('CaseDetail', { id: created.id });
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe} edges={['bottom']}>
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView
          contentContainerStyle={styles.scroll}
          keyboardShouldPersistTaps="handled"
        >
          <Field
            label="クライアント名"
            value={clientName}
            onChangeText={setClientName}
            placeholder="株式会社ノヴァ"
          />
          <Field
            label="案件名（任意）"
            value={title}
            onChangeText={setTitle}
            placeholder="技術顧問ライト"
          />

          <View style={styles.group}>
            <Text style={styles.groupLabel}>種別</Text>
            <View style={styles.chips}>
              {(Object.keys(typeMeta) as CaseType[]).map((key) => (
                <SelectableChip
                  key={key}
                  label={typeMeta[key].label}
                  color={typeMeta[key].color}
                  active={type === key}
                  onPress={() => setType(key)}
                />
              ))}
            </View>
          </View>

          <View style={styles.group}>
            <Text style={styles.groupLabel}>ステータス</Text>
            <View style={styles.chips}>
              {(Object.keys(statusMeta) as CaseStatus[]).map((key) => (
                <SelectableChip
                  key={key}
                  label={statusMeta[key].label}
                  color={statusMeta[key].color}
                  active={status === key}
                  onPress={() => setStatus(key)}
                />
              ))}
            </View>
          </View>

          <Field
            label={type === 'retainer' ? '月額（円）' : '見積／単価（円）'}
            value={amount}
            onChangeText={setAmount}
            keyboardType="number-pad"
            placeholder="120000"
          />
          <Field
            label="次アクション"
            value={nextAction}
            onChangeText={setNextAction}
            placeholder="定例アジェンダを送る"
          />
          <Field
            label="次回定例日（YYYY-MM-DD）"
            value={nextMeetingDate}
            onChangeText={setNextMeetingDate}
            placeholder="2026-09-20"
            autoCapitalize="none"
          />
          <Field
            label="請求予定日（YYYY-MM-DD）"
            value={invoiceDueDate}
            onChangeText={setInvoiceDueDate}
            placeholder="2026-09-30"
            autoCapitalize="none"
          />
          <Field
            label="メモ"
            value={notes}
            onChangeText={setNotes}
            placeholder="範囲、超過単価、断り事項など"
            multiline
          />

          <PrimaryButton
            label={saving ? '保存中…' : editing ? '変更を保存' : '案件を追加'}
            onPress={onSave}
            disabled={saving}
          />
        </ScrollView>
      </KeyboardAvoidingView>
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
  scroll: {
    padding: 20,
    gap: 16,
    paddingBottom: 40,
  },
  group: {
    gap: 8,
  },
  groupLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.muted,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
});
