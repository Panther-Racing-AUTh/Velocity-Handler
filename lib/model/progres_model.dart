import 'package:flutter/material.dart';

class ProcessingPage extends StatefulWidget {
  final bool testCheck;

  ProcessingPage({Key? key, required this.testCheck}) : super(key: key);

  @override
  _ProcessingPageState createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],  // Light background color
      
      body: Center(
        child: ProcessingPageIndicator(
          isProcessing: widget.testCheck,
          message: "Please wait while processing test...", // Clear and friendly message
        ),
      ),
    );
  }
}

class ProcessingPageIndicator extends StatelessWidget {
  final bool isProcessing;
  final String message;

  const ProcessingPageIndicator({
    Key? key,
    required this.isProcessing,
    this.message = "Processing...",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isProcessing
          ? _buildProcessingView(context)
          : const SizedBox.shrink(), // If not processing, show nothing
    );
  }

  Widget _buildProcessingView(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .4,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 4), // Soft shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 6,  // Thicker loading circle
            valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 33, 21, 146)),
          ),
          const SizedBox(height: 30),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
