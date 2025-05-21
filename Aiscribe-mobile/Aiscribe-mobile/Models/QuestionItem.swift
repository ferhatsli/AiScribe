import Foundation

struct QuestionItem: Identifiable, Hashable {
    let id: UUID
    let question: String
    let examples: [String]
    
    init(question: String, examples: [String]) {
        self.id = UUID()
        self.question = question
        self.examples = examples
    }
    
    init(from question: Question) {
        self.id = UUID()
        self.question = question.question
        self.examples = question.examples
    }
} 