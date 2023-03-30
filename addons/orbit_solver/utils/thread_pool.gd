extends Node
class_name ThreadPool


const THREADED := true
const DEBUG := false
const THREADS := -1
const WORK_PER_THREAD := 100
const WORK_PER_THREAD_INCREASE_AMOUNT := 100
const WORK_PER_THREAD_MAX_INCREASE := 200


class ThreadPoolUnit:
	extends Thread
	
	var idle := true


var _thread_pool: Array[ThreadPoolUnit]
var _work_per_thread := WORK_PER_THREAD


func _ready() -> void:
	process_priority = ProcessPriority.SOLVER

	if THREADED:
		# We have no easy way of knowing whether
		# the current Processor has HyperThreading or not.
		# So we just assume it doesn't.
		for i in range(OS.get_processor_count() if THREADS < 1 else THREADS):
			_thread_pool.append(ThreadPoolUnit.new())


func _physics_process(delta: float) -> void:
	if DEBUG:
		prints(
			"Threads:",
			_thread_pool
				.filter(func(unit: ThreadPoolUnit): return not unit.busy)
				.size()
		)


## Actually execute the work.
func _execute_work(work: Array, job: Callable, threads_override = -1) -> Array[ThreadPoolUnit]:
	if not THREADED:
		job.bind(work).call()
		return []
	
	var amount_of_work := work.size()
	var waiting_threads: Array[ThreadPoolUnit] = []
	var i := 0
	for unit in _thread_pool:
		if not unit.idle or unit.is_alive():
			if not unit.is_alive() and unit.is_started():
				unit.wait_to_finish()
				unit.idle = true
			
			continue
		
		if unit.is_started():
			unit.wait_to_finish()
		
		waiting_threads.append(unit)
		
		if threads_override > 0 and waiting_threads.size() == threads_override:
			break
		
		i += _work_per_thread
		if i > amount_of_work:
			break
	
	# if no idle theads are available on the pool, create an ad-hoc one
	if waiting_threads.is_empty():
		waiting_threads.append(ThreadPoolUnit.new())
	
	i = 0
	var work_per_thread := ceili(float(amount_of_work) / waiting_threads.size())
	for unit in waiting_threads:
		unit.idle = false
		if waiting_threads[-1] == unit:
			unit.start(job.bind(work.slice(i), unit))
		else:
			unit.start(job.bind(work.slice(i, i + work_per_thread), unit))
		i += work_per_thread

	if waiting_threads.size() <= 0 or waiting_threads.size() == _thread_pool.size():
		if _work_per_thread - WORK_PER_THREAD > WORK_PER_THREAD_MAX_INCREASE:
			if DEBUG:
				push_warning("All threads are busy, already at max thread capacity")
		else:
			_work_per_thread += WORK_PER_THREAD_INCREASE_AMOUNT
			if DEBUG:
				push_warning("All threads are busy, increasing thread capacity")
				push_warning("Increased thread capacity to %s" % _work_per_thread)
	
	return waiting_threads


# Thread must be disposed (or "joined"), for portability.
func _exit_tree():
	for unit in _thread_pool:
		if unit.is_started():
			# Wait until it exits.
			unit.wait_to_finish()
