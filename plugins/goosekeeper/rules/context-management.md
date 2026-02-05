# Context Management

## Automatic Context Monitoring

Monitor your context window usage during sessions. The system provides context info in `<ctx_window>` tags.

### 60% Threshold Rule

When context usage exceeds **60%** (i.e., less than 40% tokens remaining):

1. **Save State First**
   - Update `~/.claude/my/session.json` if not already done
   - Write detailed handoff notes to `tasks/<id>/progress.md`
   - Manually log a history entry with what was accomplished

2. **Run Compact**
   - Execute `/compact` to reduce context
   - This preserves important context while freeing space

3. **Continue Work**
   - After compact, resume where you left off
   - The session.json and progress.md preserve your context

### How to Calculate Usage

Context window sizes vary by model. Trigger compact when **less than 40% remains**:
- Opus 4.6 (1M context): less than 400k tokens left → trigger compact
- Opus 4.5 (~200k context): less than 80k tokens left → trigger compact
- Sonnet 4.5 (~200k context): less than 80k tokens left → trigger compact

### Non-Interrupting Workflow

This should be seamless:
1. Notice context is high
2. Finish current atomic task (don't stop mid-thought)
3. Save state
4. Compact
5. Continue

### PreCompact Hook

If you run `/compact` manually, the PreCompact hook (if configured) will automatically:
- Ensure session.json is up to date
- Log history entry
- Update progress.md timestamp

This makes compact safe to run anytime without losing context.
