/**
 * PDF_Tools.js - Final Combined Library
 */

async function PDF_ExtractToJSON() {
    try {
        const pdfUrl = window.PDFViewerApplication.url;
        const pdf = await pdfjsLib.getDocument(pdfUrl).promise;
        const meta = await pdf.getMetadata();
        let pdfData = {
            type: 'PDF_DATA_PACKAGE',
            metadata: {
                title: meta.info.Title || 'N/A',
                author: meta.info.Author || 'N/A',
                pagesCount: pdf.numPages
            },
            pages: []
        };
        for (let i = 1; i <= pdf.numPages; i++) {
            const page = await pdf.getPage(i);
            const content = await page.getTextContent();
            pdfData.pages.push({
                pageIndex: i,
                text: content.items.map(item => item.str).join(' ')
            });
        }
        window.chrome.webview.postMessage(JSON.stringify(pdfData));
    } catch (e) {
        window.chrome.webview.postMessage(JSON.stringify({type: 'error', message: e.message}));
    }
}

async function PDF_ExtractLegacy() {
    try {
        const pdfUrl = window.PDFViewerApplication.url;
        const pdf = await pdfjsLib.getDocument(pdfUrl).promise;
        let fullText = "";
        for (let i = 1; i <= pdf.numPages; i++) {
            const page = await pdf.getPage(i);
            const textContent = await page.getTextContent();
            fullText += "[Page " + i + "]\n" + textContent.items.map(item => item.str).join(" ") + "\n\n";
        }
        window.chrome.webview.postMessage("PDF_TEXT_RESULT|" + fullText);
    } catch (error) {
        window.chrome.webview.postMessage("ERROR|" + error.message);
    }
}

// --- Highlighting Engine ---

function PDF_HighlightSpansContainingText(text, color, backColor) {
    const spans = document.querySelectorAll('.textLayer span');
    spans.forEach(span => {
        if (span.textContent.includes(text)) {
            span.style.color = color;
            span.style.backgroundColor = backColor;
            span.style.opacity = "1"; 
        }
    });
}

// Alias for PDF_HighlightAndScroll
function PDF_HighlightAndScroll(text, color, backColor) {
    const spans = document.querySelectorAll('.textLayer span');
    let firstFound = null;
    spans.forEach(span => {
        if (span.textContent.includes(text)) {
            span.style.color = color;
            span.style.backgroundColor = backColor;
            span.style.opacity = "1";
            if (!firstFound) firstFound = span;
        }
    });
    if (firstFound) firstFound.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

/**
 * Removes highlights. 
 * If 'text' is provided, it only clears matches for that text.
 * If 'text' is empty/null, it clears ALL highlights on the page.
 */
function PDF_RemoveHighlights(text = null) {
    const spans = document.querySelectorAll('.textLayer span');
    spans.forEach(span => {
        // If text is null OR if the span contains the target text
        if (!text || span.textContent.includes(text)) {
            span.style.color = "";
            span.style.backgroundColor = "";
            span.style.opacity = ""; 
        }
    });
}
