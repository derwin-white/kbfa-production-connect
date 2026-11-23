import type { Tag } from "../api/types";

export function TagChip({ tag }: { tag: Tag }) {
  return (
    <span className={`tag-chip tag-chip--${tag.tag_type}`} title={tag.category ?? undefined}>
      {tag.label}
    </span>
  );
}
