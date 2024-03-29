#!/bin/bash
clients=(1 5 10 15 20 25 30)

database=${1:-testdb}
IP=${2:-localhost}
PORT=${3:-5432}
DB_USER=${4:-postgres}
OUTPUT_DIR=${5:-"$DB_USER@$IP:$PORT"}

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit 1

#read_nopgpool
{
	echo "set terminal png"
	echo "set title 'Reads'"
	echo "set output 'read_nslaves.png'"
	echo "set xrange [1:31]"
	echo "set xlabel \"Clients\""
	echo "set ylabel \"Latency [ms]\""
	echo "plot 'data_read_nslaves.gp' using 1:2 title \"Latency\" pt 7 ps 1"
} > read_nslaves.gp

if [ -f data_read_nslaves.gp ]; then
	rm data_read_nslaves.gp
fi
for i in "${clients[@]}"; do
	latency=$(pgbench -T 60 -c "$i" -S -h "$IP" -p "$PORT" -U "$DB_USER" "$database" | awk '/latency/ {print $4}')
	echo "$i $latency" >> data_read_nslaves.gp
done
gnuplot read_nslaves.gp

#write_nopgpool
{
	echo "set terminal png"
	echo "set title 'Writes'"
	echo "set output 'write_nslaves.png'"
	echo "set xrange [1:31]"
	echo "set xlabel \"Clients\""
	echo "set ylabel \"Latency [ms]\""
	echo "plot 'data_write_nslaves.gp' using 1:2 title \"Latency\" pt 7 ps 1"
} > write_nslaves.gp

if [ -f data_write_nslaves.gp ]; then
	rm data_write_nslaves.gp
fi
for i in "${clients[@]}"; do
	latency=$(pgbench -T 60 -c "$i" -h "$IP" -p "$PORT" -U "$DB_USER" "$database" | awk '/latency/ {print $4}')
	echo "$i $latency" >> data_write_nslaves.gp
done
gnuplot write_nslaves.gp

file1="data_write_nslaves.gp"
file1col1=()
file1col2=()
while IFS= read -r line; do
	#echo "$line" | awk '{print $1}'
	#echo "col2: $col2"
	file1col1+=("$(echo "$line" | awk '{print $1}')")
	file1col2+=("$(echo "$line" | awk '{print $2}')")
	#echo "col1: $col1"
done < "$file1"

file2="data_read_nslaves.gp"
file2col1=()
file2col2=()
while IFS= read -r line; do
	file2col1+=("$(echo "$line" | awk '{print $1}')")
	file2col2+=("$(echo "$line" | awk '{print $2}')")
done < "$file2"

line=()
end=${#file1col1[@]}
if [ -f data_rw_nslaves.gp ]; then
	rm data_rw_nslaves.gp
fi
for i in $(seq 0 "$end"); do
	#line[i]="${file1col1[i]} ${file1col2[i]} ${file2col2[i]}"
	echo "${file1col1[i]} ${file1col2[i]} ${file2col2[i]}" >> data_rw_nslaves.gp
	#line+=($(echo "${file1col1[i]} ${file1col1[i]} ${file2col2[i]}"))
done

for i in "${line[@]}"; do
	echo "$i"
done

{
	echo "set terminal png"
	echo "set title 'Reads and Writes'"
	echo "set output 'rw_nslaves.png'"
	echo "set xrange [1:31]"
	echo "set xlabel \"Clients\""
	echo "set ylabel \"Latency [ms]\""
	echo "plot 'data_rw_nslaves.gp' using 1:2 title \"write\" pt 7 ps 1, '' using 1:3 title \"read\" pt 7 ps 1"
} > rw_nslaves.gp

gnuplot rw_nslaves.gp
