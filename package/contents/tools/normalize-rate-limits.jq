def number_or_zero:
    if type == "number" then
        .
    elif type == "string" then
        try tonumber catch 0
    else
        0
    end;

def optional_number:
    if . == null then null else number_or_zero end;

def clamp_percent:
    if . < 0 then 0 elif . > 100 then 100 else . end;

def normalize_window:
    if . == null then
        null
    else
        (.usedPercent | number_or_zero | floor | clamp_percent) as $used
        | {
            remainingPercent: (100 - $used | clamp_percent),
            resetsAt: (.resetsAt | optional_number)
        }
    end;

(.result | if type == "object" then . else {} end) as $result
| ([
    $result.rateLimits,
    ($result.rateLimitsByLimitId
        | if type == "object" then .[] else empty end)
] | map(select(type == "object"))) as $buckets
| ([
    $buckets[]
    | .primary,
      .secondary,
      (.windows | if type == "array" then .[] else empty end)
] | map(select(type == "object"))) as $windows
| (first(
    $windows[]
    | select((.windowDurationMins | number_or_zero) == 10080)
) // null | normalize_window) as $weekly
| {
    ok: true,
    weeklyWindow: $weekly,
    fetchedAt: (now | floor)
}
