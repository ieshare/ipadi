import { Pressable, StyleSheet, Text, View } from 'react-native';

import { amountKindLabel, colors, typeMeta } from '../theme';
import type { CaseItem } from '../types';
import { formatYen } from '../utils/format';
import { StatusBadge, TypeBadge } from './Badges';

export function CaseCard({
  item,
  onPress,
}: {
  item: CaseItem;
  onPress: () => void;
}) {
  const typeColor = typeMeta[item.type].color;

  return (
    <Pressable onPress={onPress} style={styles.card}>
      <View style={[styles.accent, { backgroundColor: typeColor }]} />
      <View style={styles.body}>
        <View style={styles.row}>
          <TypeBadge type={item.type} />
          <StatusBadge status={item.status} />
        </View>
        <Text style={styles.client} numberOfLines={1}>
          {item.clientName}
        </Text>
        {item.title ? (
          <Text style={styles.title} numberOfLines={1}>
            {item.title}
          </Text>
        ) : null}
        <View style={styles.amountRow}>
          <Text style={styles.kind}>{amountKindLabel[item.type]}</Text>
          <Text style={styles.amount}>{formatYen(item.amount)}</Text>
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.paper,
    borderRadius: 16,
    overflow: 'hidden',
    flexDirection: 'row',
    borderWidth: 1,
    borderColor: colors.line,
  },
  accent: {
    width: 6,
  },
  body: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 8,
  },
  row: {
    flexDirection: 'row',
    gap: 8,
    flexWrap: 'wrap',
  },
  client: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.ink,
  },
  title: {
    fontSize: 13,
    color: colors.muted,
  },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: 8,
    marginTop: 2,
  },
  kind: {
    fontSize: 12,
    color: colors.muted,
    fontWeight: '600',
  },
  amount: {
    fontSize: 20,
    fontWeight: '800',
    color: colors.copper,
    letterSpacing: 0.3,
  },
});
