/// DTO for creating a new NIC application
/// Sends form data as JSON with separate attachment handling
class ApplicationCreateDto {
  /// The type of form being submitted
  final String formType;
  
  /// Complete form data as a dynamic JSON object
  /// This includes all the form fields from the multi-step form
  final Map<String, dynamic> formData;
  
  /// List of file attachments that need to be uploaded
  /// Each attachment contains file metadata and references
  final List<ApplicationAttachment> attachments;

  const ApplicationCreateDto({
    required this.formType,
    required this.formData,
    required this.attachments,
  });

  /// Converts to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'formType': formType,
      'formData': formData,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  /// Creates DTO from the dynamic form data collected from multi-step form
  static ApplicationCreateDto fromDynamicFormData(
    String formType,
    Map<String, dynamic> rawFormData,
  ) {
    final attachments = <ApplicationAttachment>[];
    final cleanFormData = <String, dynamic>{};

    // Separate file fields from regular form data
    for (final entry in rawFormData.entries) {
      final value = entry.value;
      
      // Check if the value is a file object
      if (value is Map<String, dynamic> && 
          value.containsKey('path') && 
          value.containsKey('mimeType')) {
        
        // Extract file information and create attachment
        attachments.add(ApplicationAttachment(
          fieldId: entry.key,
          fileName: value['name'] ?? 'unknown',
          filePath: value['path'],
          mimeType: value['mimeType'],
          fileSize: value['size'] ?? 0,
        ));
        
        // Store file reference in form data (will be replaced with uploaded URL/ID)
        cleanFormData[entry.key] = {
          'type': 'file_reference',
          'fieldId': entry.key,
          'fileName': value['name'],
          'mimeType': value['mimeType'],
        };
      } else {
        // Regular form field, include as-is
        cleanFormData[entry.key] = value;
      }
    }

    return ApplicationCreateDto(
      formType: formType,
      formData: cleanFormData,
      attachments: attachments,
    );
  }

  /// Returns a copy with uploaded file URLs/IDs replacing file references
  ApplicationCreateDto withUploadedFiles(Map<String, String> uploadedFileUrls) {
    final updatedFormData = Map<String, dynamic>.from(formData);
    
    // Replace file references with actual uploaded URLs/IDs
    for (final entry in uploadedFileUrls.entries) {
      final fieldId = entry.key;
      final fileUrl = entry.value;
      
      if (updatedFormData.containsKey(fieldId)) {
        updatedFormData[fieldId] = fileUrl;
      }
    }

    return ApplicationCreateDto(
      formType: formType,
      formData: updatedFormData,
      attachments: [], // Attachments are processed, no longer needed
    );
  }


}

/// Represents a file attachment in the application
class ApplicationAttachment {
  /// The form field ID this attachment belongs to
  final String fieldId;
  
  /// Original file name
  final String fileName;
  
  /// Local file path (for upload)
  final String filePath;
  
  /// MIME type of the file
  final String mimeType;
  
  /// File size in bytes
  final int fileSize;

  const ApplicationAttachment({
    required this.fieldId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
  });

  /// Converts to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'fileName': fileName,
      'filePath': filePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
    };
  }

  /// Creates attachment from file field data
  static ApplicationAttachment fromFileField(
    String fieldId,
    Map<String, dynamic> fileData,
  ) {
    return ApplicationAttachment(
      fieldId: fieldId,
      fileName: fileData['name'] ?? 'unknown',
      filePath: fileData['path'] ?? '',
      mimeType: fileData['mimeType'] ?? 'application/octet-stream',
      fileSize: fileData['size'] ?? 0,
    );
  }
}

/// Response DTO for successful application creation
class ApplicationCreateResponse {
  /// The created application ID
  final String applicationId;
  
  /// Status of the application
  final String status;
  
  /// Any additional metadata
  final Map<String, dynamic>? metadata;

  const ApplicationCreateResponse({
    required this.applicationId,
    required this.status,
    this.metadata,
  });

  /// Creates from JSON response
  factory ApplicationCreateResponse.fromJson(Map<String, dynamic> json) {
    // Handle the nested response structure from the backend
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    return ApplicationCreateResponse(
      applicationId: data['id'] as String,
      status: data['currentStatus'] as String? ?? 'SUBMITTED',
      metadata: data,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'status': status,
      'metadata': metadata,
    };
  }
}
