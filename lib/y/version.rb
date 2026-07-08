# frozen_string_literal: true

module Y
  # Tektome fork: 0.7.0 upstream + the yrs apply_delete in-store range-delete
  # backport (upstream y-crdt@97095f2). The trailing .1 marks the patched build
  # and keeps it off rubygems so the app can only ever resolve it from the
  # vendored gem, never the unpatched upstream 0.7.0.
  VERSION = "0.7.0.1"
end
