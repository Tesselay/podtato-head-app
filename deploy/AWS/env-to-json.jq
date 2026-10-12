# Turns the KEY=value lines of a .env file into one JSON object for Secrets Manager.
# `make secrets` runs it for you; to preview what would be stored, run:
#
#   jq -Rn -f env-to-json.jq < .env.dev
#
# Blank lines and # comments are skipped, a leading "export " is allowed, the value is
# everything after the first "=", and one pair of matching quotes around it is removed.
# Comments after a value on the same line are not supported: they would become part of it.
[ inputs
  | sub("\r$"; "")
  | sub("^\\s*(export\\s+)?"; "")
  | select(test("^[A-Za-z_][A-Za-z0-9_]*="))
  | capture("^(?<key>[^=]+)=(?<value>.*)$")
  | .value |= sub("^(?<q>[\"'])(?<inner>.*)\\k<q>$"; "\(.inner)")
  | { (.key): .value }
]
| add // {}
