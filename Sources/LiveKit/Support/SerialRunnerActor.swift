/*
 * Copyright 2024 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

actor SerialRunnerActor<Value: Sendable> {
    private var previousTask: Task<Value, Error>?
    
    private func createTask<T>(
        block: @Sendable @escaping () async throws -> T
    ) -> Task<T, Error> {
        Task { [previousTask] in
            // Wait for the previous task to complete, but cancel it if needed
            if let previousTask, !Task.isCancelled {
                // If previous task is still running, wait for it
                _ = try? await previousTask.value
            }

            // Check for cancellation before running the block
            try Task.checkCancellation()

            // Run the new block
            return try await block()
        }
    }

    // Throwing version
    func run(block: @Sendable @escaping () async throws -> Value) async throws -> Value {
        let task = createTask(block: block)
        previousTask = task

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    // Non-throwing version
    func run(block: @Sendable @escaping () async -> Value) async -> Value {
        let task = createTask { await block() }
        previousTask = task

        return await withTaskCancellationHandler {
            try! await task.value // the task is guaranteed to be non-throwing because block() is non-throwing
        } onCancel: {
            task.cancel()
        }
    }
}
