import { Pressable, StyleSheet, Text, View } from 'react-native';

import { statusMeta, typeMeta } from '../theme';
import type { CaseStatus, CaseType } from '../types';

export function TypeBadge({ type }: { type: CaseType }) {
  const meta = typeMeta[type];
  return (
    <View style={[styles.badge, { backgroundColor: meta.soft }]}>
      <Text style={[styles.text, { color: meta.color }]}>{meta.label}</Text>
    </View>
  );
}

export function StatusBadge({ status }: { status: CaseStatus }) {
  const meta = statusMeta[status];
  return (
    <View style={[styles.badge, { backgroundColor: meta.soft }]}>
      <Text style={[styles.text, { color: meta.color }]}>{meta.label}</Text>
    </View>
  );
}

export function SelectableChip({
  label,
  active,
  color,
  onPress,
}: {
  label: string;
  active: boolean;
  color: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.chip,
        active && { backgroundColor: color, borderColor: color },
      ]}
    >
      <Text style={[styles.chipText, active && styles.chipTextActive]}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  badge: {
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  text: {
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 0.2,
  },
  chip: {
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#E4D9C8',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#FFFBF5',
  },
  chipText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#1B2420',
  },
  chipTextActive: {
    color: '#FFFBF5',
  },
});
