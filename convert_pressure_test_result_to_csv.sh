#! /bin/sh

echo "please enter api name -> "
read api

echo "please enter total request number, step of concurrency, max of concurrency -> "
read total_request concurrency_step max_concurrency

echo "please enter http headers (option) -> (Cookie:session=6785327;)"
read headers

echo "please enter target url -> "
read target

base_dir=/tmp/pressure_test
mkdir ${base_dir}

date=`date +%Y-%m-%d_%H-%M`
test_log=${base_dir}/pressure_test_${api}_${date}.log
csv_file=${base_dir}/pressure_test_${api}_${date}.csv

current_concurrency=0

add_concurrency_step(){
    current_concurrency=`expr ${current_concurrency} + ${concurrency_step}`
    if [ ${current_concurrency} -gt ${max_concurrency} ]; then
        current_concurrency=${max_concurrency}
    fi
}

execute_pressure_test(){
    echo "\n==> executor: ab -n${total_request} -c${current_concurrency} -H '${headers}' ${target} \n"
    ab -n${total_request} -c${current_concurrency} -H '${headers}' ${target} >> ${test_log}
}

convert_test_result_to_csv(){
    echo "write csv ${csv_file}"

    # file header
    echo "Concurrency Level, Time taken for tests(sec), Complete request, Failed requests, Requests per second, \c" >> ${csv_file}
    echo "Time per request of client(ms), Time per request of server(ms), Transfer rate(Kb/sec), 90% User Time per request(ms)" >> ${csv_file}

    while read line; do
        # new circle of test
        if ( echo ${line} | grep 'Concurrency Level' ) ; then
            echo `echo ${line} | awk '{print $3}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Time taken for tests' ) ; then
            echo ","`echo ${line} | awk '{print $5}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Complete requests' ) ; then
            echo ","`echo ${line} | awk '{print $3}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Failed requests' ) ; then
            echo ","`echo ${line} | awk '{print $3}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Requests per second' ) ; then
            echo ","`echo ${line} | awk '{print $4}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Time per request' | grep -v 'across all concurrent requests' ) ; then
            echo ","`echo ${line} | awk '{print $4}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Time per request' | grep 'across all concurrent requests' ) ; then
            echo ","`echo ${line} | awk '{print $4}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep 'Transfer rate' ) ; then
            echo ","`echo ${line} | awk '{print $3}'`"\c" >> ${csv_file}
        fi

        if ( echo ${line} | grep '90%' ) ; then
            echo ","`echo ${line} | awk '{print $2}'` >> ${csv_file}
            echo "\n================ *** *** =====================\n"
        fi
    done < ${test_log}

    echo "finish write csv ${csv_file}"

    echo "rm ${test_log}"
    rm ${test_log}
}

while [ ${current_concurrency} -lt ${max_concurrency} ]; do
    add_concurrency_step
    execute_pressure_test
done

convert_test_result_to_csv
