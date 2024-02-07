	#!/bin/bash
    mkdir -p build
    echo "#!/bin/bash" > build/standup_generator.sh
	for file in `find src -name '*.sh' | sort`; do 
		cat $file >> build/standup_generator.sh
		echo "" >> build/standup_generator.sh
	done

    chmod +x build/standup_generator.sh
