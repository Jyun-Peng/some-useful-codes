export class AsyncFuncQueue {
    constructor({ concurrency = 1 }) {
        this.concurrency = concurrency;
        this.queue = [];
        this.command_number = 0;
    }

    push(command) {
        return new Promise((resolve, _) => {
            const new_command = async () => {
                const res = await command();
                resolve(res);
                
                this.command_number--;

                const next_command = this.queue.shift() ?? null;
                if(next_command !== null) {
                    next_command();
                }
            }
            
            this.command_number++;

            if(this.command_number <= this.concurrency) {
                new_command();
            } else {
                this.queue.push(new_command);
            }
        })
    }
}