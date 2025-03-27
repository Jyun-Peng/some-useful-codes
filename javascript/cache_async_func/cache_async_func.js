/**
 * Creates a cached version of an asynchronous function, reusing results based on a time-based cache and argument key.
 * @param {function(...*): Promise<*>} func - The asynchronous function to cache. Accepts any arguments and returns a Promise. 
 * @param {Object} [options] - Configuration options for caching behavior.
 * @param {number} [options.keep_sec=300] - The duration (in seconds) to keep the cached result before invalidating it. Defaults to 300 seconds (5 minutes).
 * @param {function(Array): string|number} [options.args_cache_key] - A function that generates a cache key from the arguments. Defaults to returning the current timestamp.
 * @returns {function(...*): Promise<*>} A closure that caches the result of `func`, returning a Promise with the cached or fresh result.
 */
export function cache_async_func(func, options = null) {
    const {
        keep_sec = 300,
        args_cache_key = args => new Date().getTime()
    } = options ?? {};

    let running_promise = null;
    let cache_result = null;
    let cache_time = null;
    let cache_key = null;

    return async (...args) => {
        const now = new Date().getTime();
        const new_cache_key = args_cache_key(args);
        if(cache_result && cache_key === new_cache_key && (now - cache_time) <= keep_sec * 1000) {
            return cache_result;
        }

        if(!running_promise) {
            running_promise = func(...args).then(res => {
                running_promise = null;
                cache_result = res;
                cache_time = new Date().getTime();
                cache_key = new_cache_key;
            });
        }
        
        await running_promise;
        return cache_result;
    }
}