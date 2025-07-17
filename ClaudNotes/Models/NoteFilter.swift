//
//  NoteFilter.swift
//  ClaudNotes
//
//  Created by Kartikay Shukla on 17/07/25.
//

import Foundation

/// Enum to define different filtering options for notes
enum NoteFilter {
    case all
    case folder(Folder)
    case tag(Tag)
    case recent
    case pinned
}

// NoteSortOrder is already defined elsewhere in the project, so we're removing it from this file