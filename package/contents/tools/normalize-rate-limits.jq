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

def optional_string:
    if type == "string" and length > 0 then . else null end;

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
| ($result.rateLimitResetCredits
    | if type == "object" then
        {
            availableCount: (.availableCount | number_or_zero | floor | if . < 0 then 0 else . end),
            credits: (
                .credits
                | if type == "array" then
                    [
                        .[]
                        | select(type == "object")
                        | {
                            title: (.title | optional_string),
                            description: (.description | optional_string),
                            expiresAt: (.expiresAt | optional_number)
                        }
                    ]
                else null end
            )
        }
      else null end
) as $reset_credits
| {
    ok: true,
    weeklyWindow: $weekly,
    rateLimitResetCredits: $reset_credits,
    fetchedAt: (now | floor)
}
