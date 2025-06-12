#!/bin/sh
# Script to Retrieve some Port details from a target SR-Linux node/interface
# Change the username/password as required
# Assumption is that the interface will start with "ethernet-"  input will add the port number

program=$0

HOSTNAME=""
PORT="57400"	# Default port if not specified
INTERFACE_NAME=""
USER="some_user"
PASSWORD="not_a_real_password"

usage() {
  echo "Usage: $0 -h <hostname> [-p <port>] -i <interface_name>"
  echo "Options:"
  echo "  -h <hostname>        : The hostname or IP address (e.g., example.com or 192.168.1.1) (Mandatory)"
  echo "  -p <port>            : The port number (e.g., 80, 443, 22). Defaults to 57400 if not specified."
  echo "  -i <interface_name>  : The network interface name (e.g., eth0, enp0s3, wlan0) (Mandatory)"
  exit 1
}

while getopts "h:p:i:" opt; do
  case "$opt" in
    h)
      HOSTNAME="$OPTARG"
      ;;
    p)
      PORT="$OPTARG"
      ;;
    i)
      INTERFACE_NAME="$OPTARG"
      ;;
    \?) # Handle invalid options
      echo "Error: Invalid option -$OPTARG." >&2
      usage
      ;;
    :) # Handle missing option arguments
      echo "Error: Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Shift off the options and their arguments so "$@" refers to the remaining arguments (should be none)
shift $((OPTIND-1))

# --- Input Validation ---
# Validate if all required inputs are provided
if [ -z "$HOSTNAME" ]; then
  echo "Error: Hostname is required. Use -h <hostname>."
  usage
fi

if [ -z "$INTERFACE_NAME" ]; then
  echo "Error: Interface name is required. Use -i <interface_name>."
  usage
fi

# Validate port if it was explicitly provided or if the default is in an invalid state (shouldn't happen with 57400)
# Ensure it's a number and within a valid range 1-65535
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -le 0 ] || [ "$PORT" -gt 65535 ]; then
  echo "Error: Port must be a valid number between 1 and 65535."
  usage
fi

# If all inputs are valid, print them
echo "Inputs verified successfully!"
echo "Hostname: $HOSTNAME"
echo "Port: $PORT"
echo "Interface Name: $INTERFACE_NAME"


result=`gnmic -a $HOSTNAME:$PORT -u $USER -p $PASSWORD --skip-verify -e JSON_IETF get --prefix "/interface[name=ethernet-${INTERFACE_NAME}]" --values-only \
--path "ethernet/port-speed" \
--path "admin-state" \
--path "oper-state" \
--path "description" \
--path "traffic-rate/in-bps" \
--path "traffic-rate/out-bps" \
--path "ethernet/statistics/in-crc-error-frames" \
--path "ethernet/statistics/in-fragment-frames" \
--path "ethernet/statistics/in-jabber-frames" \
--path "ethernet/statistics/out-mac-pause-frames" \
--path "ethernet/statistics/in-oversize-frames" \
--path "transceiver/input-power/latest-value" \
--path "transceiver/output-power/latest-value" \
--path "ethernet/statistics/last-clear"` 

##convert string to array
a=${result// /}		#remove whitespaces
a=${a//,/ }		#replace comma with whitespace
a=${a##[}		#remove open square bracket
a=${a%]}		#remove close square bracket
eval values_array=($a)

#Define Column headers
header1="Speed"
header2="Admin"
header3="Oper"
header4="Description"
header5="in-bps"
header6="out-bps"
header7="in crc err"
header8="in Frag"
header9="in Jabber"
header10="out mac pause"
header11="in oversize"
header12="input dB"
header13="output dB"
header14="last clear"

# Use printf for structured output. Adjust column widths (%-12s for left-aligned, 12 chars wide)
# Row 1 Headers
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "$header1" "$header2" "$header3" "$header4" "$header5" "$header6" "$header7"

# Separator for headers
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "------------" "------------" "------------" "------------" "------------" "------------" "------------"

# Row 1 Data (first 7 values)
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "${values_array[0]}" "${values_array[1]}" "${values_array[2]}" "${values_array[3]}" \
  "${values_array[4]}" "${values_array[5]}" "${values_array[6]}"

echo "" # Blank line between rows for clarity if needed

# Row 2 Headers (optional, or you can integrate them differently)
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "$header8" "$header9" "$header10" "$header11" "$header12" "$header13" "$header14"

# Separator for headers
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "------------" "------------" "------------" "------------" "------------" "------------" "------------"

# Row 2 Data (next 7 values)
printf "%-12s %-12s %-12s %-12s %-12s %-12s %-12s\n" \
  "${values_array[7]}" "${values_array[8]}" "${values_array[9]}" "${values_array[10]}" \
  "${values_array[11]}" "${values_array[12]}" "${values_array[13]}"

echo "" # Add a blank line at the end
# --- End of Table Output ---

