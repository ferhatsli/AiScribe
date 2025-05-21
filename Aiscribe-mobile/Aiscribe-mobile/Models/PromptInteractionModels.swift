import Foundation

// MARK: - Request Models
struct AnswerItem: Codable, Hashable {
    let question: String
    let answer: String
}

struct PromptRequest: Codable {
    let prompt: String
    let autoExpand: Bool?
    let languageCode: String?
    let selectedExpansionIndex: Int?
    let answers: [AnswerItem]?
    let style: String?

    init(prompt: String, autoExpand: Bool? = false, languageCode: String? = nil, selectedExpansionIndex: Int? = nil, answers: [AnswerItem]? = nil, style: String? = nil) {
        self.prompt = prompt
        self.autoExpand = autoExpand
        self.languageCode = languageCode
        self.selectedExpansionIndex = selectedExpansionIndex
        self.answers = answers
        self.style = style
    }

    enum CodingKeys: String, CodingKey {
        case prompt
        case autoExpand = "auto_expand"
        case languageCode = "language_code"
        case selectedExpansionIndex = "selected_expansion_index"
        case answers
        case style
    }
}

// MARK: - Response Models
struct Question: Codable {
    let module: String
    let question: String
    let examples: [String]
}

struct PromptResponse: Codable {
    let status: String
    let finalPrompt: String?
    let expansions: [String]?
    let questions: [Question]?
    let qaList: [AnswerItem]?
    let categorizedElements: [String: [String]]?
    let languageCode: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case status
        case finalPrompt = "final_prompt"
        case expansions
        case questions
        case qaList = "qa_list"
        case categorizedElements = "categorized_elements"
        case languageCode = "language_code"
        case errorMessage = "error_message"
    }
} 