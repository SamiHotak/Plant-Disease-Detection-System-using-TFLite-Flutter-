/// Agronomic reference information shown alongside a prediction.
class DiseaseInfo {
  final String name;
  final String severity; // none | low | moderate | high
  final String summary;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;

  const DiseaseInfo({
    required this.name,
    required this.severity,
    required this.summary,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
  });
}

/// Looks up guidance for a model label.
///
/// The model emits raw PlantVillage labels such as `Tomato___Early_blight`.
/// Rather than requiring an exact key for all 38 classes, [lookup] normalises
/// the label and scores it against the entries below, so a class the library
/// does not cover explicitly still resolves to the closest sensible match —
/// and falls back to generic guidance if nothing scores well enough.
class DiseaseLibrary {
  DiseaseLibrary._();

  static const DiseaseInfo healthy = DiseaseInfo(
    name: 'Healthy',
    severity: 'none',
    summary:
        'No disease detected. The leaf shows normal colour, texture and '
        'margins for a healthy plant.',
    symptoms: [
      'Uniform green colouring with no chlorosis',
      'No lesions, spots or powdery growth',
      'Firm, intact leaf margins',
    ],
    treatment: [
      'No treatment required',
      'Continue the current watering and feeding routine',
    ],
    prevention: [
      'Inspect new growth weekly for early symptoms',
      'Water at the base to keep foliage dry',
      'Maintain spacing so air moves freely between plants',
    ],
  );

  static const DiseaseInfo unknown = DiseaseInfo(
    name: 'Unrecognised condition',
    severity: 'moderate',
    summary:
        'The model identified a condition that is not in the local reference '
        'library. Treat the prediction as a starting point and confirm with '
        'an agronomist before applying any chemical control.',
    symptoms: [
      'Compare the leaf against a healthy one from the same plant',
      'Note whether lesions are spreading day to day',
    ],
    treatment: [
      'Remove and destroy visibly affected leaves',
      'Isolate the plant from healthy neighbours',
      'Consult a local extension service for confirmation',
    ],
    prevention: [
      'Avoid overhead watering',
      'Sterilise pruning tools between plants',
      'Rotate crops between seasons',
    ],
  );

  /// Keyword sets are matched against the normalised label.
  static const Map<String, DiseaseInfo> _entries = <String, DiseaseInfo>{
    'early blight': DiseaseInfo(
      name: 'Early Blight',
      severity: 'moderate',
      summary:
          'A fungal disease caused by Alternaria solani. It starts on older, '
          'lower leaves and moves upward, reducing yield if left unchecked.',
      symptoms: [
        'Dark brown spots with concentric rings, like a target',
        'Yellow halo surrounding each lesion',
        'Lower and older leaves affected first',
        'Premature leaf drop in advanced cases',
      ],
      treatment: [
        'Remove and destroy affected leaves — do not compost them',
        'Apply a copper-based or chlorothalonil fungicide',
        'Repeat every 7–10 days while conditions stay humid',
        'Improve airflow by pruning dense lower growth',
      ],
      prevention: [
        'Rotate crops on a 2–3 year cycle',
        'Mulch to stop soil splashing onto lower leaves',
        'Water at soil level, never over the canopy',
        'Choose resistant cultivars where available',
      ],
    ),
    'late blight': DiseaseInfo(
      name: 'Late Blight',
      severity: 'high',
      summary:
          'Caused by Phytophthora infestans — the pathogen behind the Irish '
          'potato famine. It spreads extremely fast in cool, wet weather and '
          'can destroy a crop within days.',
      symptoms: [
        'Large water-soaked grey-green patches',
        'White fuzzy growth on the leaf underside in humidity',
        'Rapid browning and collapse of stems',
        'Firm brown rot on fruit or tubers',
      ],
      treatment: [
        'Act immediately — this disease moves in days, not weeks',
        'Remove and destroy all infected plants entirely',
        'Apply fungicide containing mancozeb or copper to survivors',
        'Do not save tubers or fruit from infected plants',
      ],
      prevention: [
        'Plant certified disease-free seed stock',
        'Avoid overhead irrigation, especially in the evening',
        'Increase spacing to speed canopy drying',
        'Destroy volunteer plants and cull piles',
      ],
    ),
    'leaf mold': DiseaseInfo(
      name: 'Leaf Mould',
      severity: 'moderate',
      summary:
          'Passalora fulva thrives in the high humidity of greenhouses and '
          'polytunnels. Rarely fatal but it steadily reduces photosynthesis.',
      symptoms: [
        'Pale green to yellow patches on the upper leaf surface',
        'Olive-green to grey velvety mould underneath',
        'Leaves curl, wither and drop',
      ],
      treatment: [
        'Increase ventilation and reduce humidity below 85%',
        'Remove affected leaves promptly',
        'Apply an approved fungicide if spread continues',
      ],
      prevention: [
        'Space plants generously and prune for airflow',
        'Avoid wetting foliage when watering',
        'Sterilise greenhouse surfaces between seasons',
      ],
    ),
    'septoria': DiseaseInfo(
      name: 'Septoria Leaf Spot',
      severity: 'moderate',
      summary:
          'Septoria lycopersici produces many small circular lesions. It '
          'defoliates plants from the bottom up, exposing fruit to sunscald.',
      symptoms: [
        'Numerous small circular spots with dark borders',
        'Grey or tan centres, often with tiny black specks',
        'Starts on the lowest leaves after fruit set',
      ],
      treatment: [
        'Strip and destroy the affected lower foliage',
        'Apply copper or chlorothalonil fungicide',
        'Mulch to block spore splash from the soil',
      ],
      prevention: [
        'Clear all plant debris at the end of the season',
        'Rotate away from solanaceous crops for 2 years',
        'Stake plants to lift foliage off the ground',
      ],
    ),
    'bacterial spot': DiseaseInfo(
      name: 'Bacterial Spot',
      severity: 'high',
      summary:
          'Xanthomonas bacteria enter through wounds and stomata. Warm, wet '
          'weather drives rapid spread, and there is no curative treatment.',
      symptoms: [
        'Small water-soaked spots turning dark and angular',
        'Yellow halos around lesions',
        'Raised scabby spots on fruit',
      ],
      treatment: [
        'No cure exists — focus on limiting spread',
        'Remove severely affected plants',
        'Apply copper-based bactericide preventively',
        'Never work among plants while foliage is wet',
      ],
      prevention: [
        'Use certified pathogen-free seed and transplants',
        'Rotate crops for at least one year',
        'Disinfect tools, stakes and trays between uses',
      ],
    ),
    'spider mite': DiseaseInfo(
      name: 'Two-Spotted Spider Mite',
      severity: 'moderate',
      summary:
          'A sap-feeding arachnid, not a pathogen. Populations explode in hot, '
          'dry conditions and can defoliate a plant quickly.',
      symptoms: [
        'Fine pale stippling across the leaf surface',
        'Delicate webbing on undersides and between stems',
        'Bronzing, then browning, of heavily fed leaves',
      ],
      treatment: [
        'Spray forcefully with water to dislodge colonies',
        'Apply insecticidal soap or horticultural oil',
        'Introduce predatory mites in enclosed growing spaces',
      ],
      prevention: [
        'Keep humidity up — mites prefer dry air',
        'Inspect leaf undersides weekly',
        'Avoid excess nitrogen, which favours mite buildup',
      ],
    ),
    'target spot': DiseaseInfo(
      name: 'Target Spot',
      severity: 'moderate',
      summary:
          'Corynespora cassiicola causes lesions with concentric rings on '
          'leaves, stems and fruit, and favours warm humid conditions.',
      symptoms: [
        'Small brown spots enlarging into ringed lesions',
        'Pitted, sunken spots on fruit',
        'Defoliation when infection is heavy',
      ],
      treatment: [
        'Remove affected foliage and fruit',
        'Apply an approved protectant fungicide',
        'Reduce leaf wetness duration',
      ],
      prevention: [
        'Space plants for airflow',
        'Rotate crops',
        'Clear debris after harvest',
      ],
    ),
    'yellow leaf curl': DiseaseInfo(
      name: 'Yellow Leaf Curl Virus',
      severity: 'high',
      summary:
          'A whitefly-transmitted virus. Infected plants cannot be cured, so '
          'management targets the insect vector.',
      symptoms: [
        'Upward curling and cupping of leaves',
        'Yellowing along leaf margins',
        'Severely stunted growth and flower drop',
      ],
      treatment: [
        'Remove and destroy infected plants to protect the rest',
        'Control whitefly with sticky traps and approved insecticides',
        'Do not attempt to save the plant — there is no cure',
      ],
      prevention: [
        'Use insect exclusion netting on young plants',
        'Plant resistant varieties in high-pressure areas',
        'Control weeds that host whitefly',
      ],
    ),
    'mosaic virus': DiseaseInfo(
      name: 'Mosaic Virus',
      severity: 'high',
      summary:
          'A highly contagious virus spread mainly by handling. It survives on '
          'tools, hands and debris for long periods.',
      symptoms: [
        'Mottled light and dark green mosaic pattern',
        'Distorted, narrow or fern-like new leaves',
        'Stunted growth and mottled fruit',
      ],
      treatment: [
        'Remove and destroy infected plants',
        'Wash hands and sterilise tools thoroughly afterwards',
        'No chemical treatment is effective',
      ],
      prevention: [
        'Do not use tobacco products near plants',
        'Sanitise tools between every plant',
        'Buy certified virus-free seed',
      ],
    ),
    'common rust': DiseaseInfo(
      name: 'Common Rust',
      severity: 'moderate',
      summary:
          'Puccinia sorghi produces powdery pustules that rupture the leaf '
          'surface. Moderate temperatures and heavy dew favour it.',
      symptoms: [
        'Small cinnamon-brown powdery pustules on both surfaces',
        'Pustules darken as the season progresses',
        'Yellowing and early senescence when severe',
      ],
      treatment: [
        'Apply a triazole or strobilurin fungicide if spread is early',
        'Remove heavily infected lower leaves',
      ],
      prevention: [
        'Plant resistant hybrids',
        'Avoid late plantings that mature in cool damp weather',
        'Scout fields weekly through the season',
      ],
    ),
    'northern leaf blight': DiseaseInfo(
      name: 'Northern Leaf Blight',
      severity: 'high',
      summary:
          'Exserohilum turcicum causes long cigar-shaped lesions. Significant '
          'yield loss follows if it reaches the upper canopy before grain fill.',
      symptoms: [
        'Long grey-green cigar-shaped lesions',
        'Lesions turn tan and may merge',
        'Lower leaves affected first',
      ],
      treatment: [
        'Apply fungicide at first sign if the crop is pre-tassel',
        'Prioritise fields with susceptible hybrids',
      ],
      prevention: [
        'Plant resistant hybrids',
        'Rotate out of maize for a season',
        'Bury residue through tillage where appropriate',
      ],
    ),
    'cercospora': DiseaseInfo(
      name: 'Cercospora Leaf Spot (Grey Leaf Spot)',
      severity: 'moderate',
      summary:
          'Produces rectangular lesions bounded by leaf veins. Favoured by '
          'prolonged high humidity and minimum-tillage residue.',
      symptoms: [
        'Narrow rectangular grey to tan lesions',
        'Lesions run parallel to veins',
        'Blighting of the whole leaf when numerous',
      ],
      treatment: [
        'Apply fungicide at early lesion development',
        'Remove crop debris where practical',
      ],
      prevention: [
        'Rotate crops',
        'Select tolerant hybrids',
        'Manage residue to reduce inoculum',
      ],
    ),
    'black rot': DiseaseInfo(
      name: 'Black Rot',
      severity: 'high',
      summary:
          'Guignardia bidwellii attacks leaves, shoots and fruit. Infected '
          'berries shrivel into hard mummies that carry the fungus over winter.',
      symptoms: [
        'Circular tan lesions with dark margins',
        'Tiny black fruiting bodies inside lesions',
        'Berries shrivel into hard black mummies',
      ],
      treatment: [
        'Remove all mummified fruit and infected canes',
        'Apply fungicide from bud break through fruit set',
        'Destroy prunings away from the vineyard',
      ],
      prevention: [
        'Prune for an open canopy',
        'Clear fallen fruit and leaves each winter',
        'Maintain a preventive spray schedule in wet regions',
      ],
    ),
    'esca': DiseaseInfo(
      name: 'Esca (Black Measles)',
      severity: 'high',
      summary:
          'A complex trunk disease of grapevines caused by several fungi. It '
          'can kill vines suddenly in hot weather.',
      symptoms: [
        'Tiger-stripe pattern between leaf veins',
        'Dark spotting on berries',
        'Sudden collapse of whole shoots or the vine',
      ],
      treatment: [
        'Cut out infected wood well below symptoms',
        'Seal large pruning wounds',
        'Replace vines that collapse repeatedly',
      ],
      prevention: [
        'Prune in dry weather late in the dormant season',
        'Protect pruning wounds',
        'Avoid stress from drought or overcropping',
      ],
    ),
    'leaf blight': DiseaseInfo(
      name: 'Leaf Blight',
      severity: 'moderate',
      summary:
          'A general fungal leaf blight producing spreading necrotic areas that '
          'reduce the plant\'s photosynthetic capacity.',
      symptoms: [
        'Irregular brown necrotic patches',
        'Lesions merging across the blade',
        'Yellowing at lesion edges',
      ],
      treatment: [
        'Remove affected foliage',
        'Apply an appropriate protectant fungicide',
        'Improve airflow around the canopy',
      ],
      prevention: [
        'Avoid overhead watering',
        'Clear fallen debris',
        'Rotate crops seasonally',
      ],
    ),
    'apple scab': DiseaseInfo(
      name: 'Apple Scab',
      severity: 'moderate',
      summary:
          'Venturia inaequalis overwinters in fallen leaves and infects during '
          'wet spring weather, blemishing fruit and weakening trees.',
      symptoms: [
        'Olive-green velvety spots turning dark and scabby',
        'Puckered and distorted leaves',
        'Rough corky lesions on fruit',
      ],
      treatment: [
        'Apply fungicide from green tip through petal fall',
        'Prune to open the canopy',
        'Rake and destroy fallen leaves',
      ],
      prevention: [
        'Plant scab-resistant cultivars',
        'Clear leaf litter every autumn',
        'Avoid overhead irrigation in spring',
      ],
    ),
    'cedar apple rust': DiseaseInfo(
      name: 'Cedar Apple Rust',
      severity: 'moderate',
      summary:
          'Requires both juniper and apple hosts to complete its life cycle, so '
          'proximity to cedars drives severity.',
      symptoms: [
        'Bright yellow-orange spots on upper leaf surfaces',
        'Tube-like structures beneath the spots',
        'Deformed fruit when infection is heavy',
      ],
      treatment: [
        'Apply fungicide from pink bud through early summer',
        'Remove nearby juniper galls where feasible',
      ],
      prevention: [
        'Avoid planting apples near junipers',
        'Choose resistant cultivars',
      ],
    ),
    'powdery mildew': DiseaseInfo(
      name: 'Powdery Mildew',
      severity: 'moderate',
      summary:
          'A white fungal coating that, unusually, thrives in warm dry weather '
          'with humid nights.',
      symptoms: [
        'White powdery coating on leaves and shoots',
        'Leaf curling and distortion',
        'Premature leaf drop',
      ],
      treatment: [
        'Apply sulphur or potassium bicarbonate sprays',
        'Prune out heavily coated shoots',
      ],
      prevention: [
        'Space plants for airflow',
        'Avoid excess nitrogen fertiliser',
        'Plant in full sun where possible',
      ],
    ),
    'leaf scorch': DiseaseInfo(
      name: 'Leaf Scorch',
      severity: 'moderate',
      summary:
          'Diplocarpon earlianum causes numerous small purple spots that '
          'coalesce, giving foliage a scorched appearance.',
      symptoms: [
        'Small dark purple spots across the blade',
        'Spots merging into scorched-looking areas',
        'Reduced runner and fruit production',
      ],
      treatment: [
        'Remove and destroy affected leaves after harvest',
        'Apply fungicide during active growth',
      ],
      prevention: [
        'Renovate beds annually',
        'Improve drainage and spacing',
        'Use disease-free planting stock',
      ],
    ),
    'haunglongbing': DiseaseInfo(
      name: 'Huanglongbing (Citrus Greening)',
      severity: 'high',
      summary:
          'A bacterial disease spread by the Asian citrus psyllid. It is fatal '
          'and incurable; management focuses on vector control and removal.',
      symptoms: [
        'Blotchy asymmetric yellowing across the leaf',
        'Small lopsided bitter fruit that stays green at the base',
        'Twig dieback and general decline',
      ],
      treatment: [
        'No cure — remove infected trees to protect the grove',
        'Control psyllid populations aggressively',
        'Notify local agricultural authorities where required',
      ],
      prevention: [
        'Plant certified disease-free nursery stock',
        'Monitor for psyllids year-round',
        'Coordinate area-wide vector management',
      ],
    ),
  };

  /// Resolve guidance for a raw model label.
  static DiseaseInfo lookup(String rawLabel) {
    final normalised = _normalise(rawLabel);

    if (normalised.contains('healthy')) return healthy;

    DiseaseInfo? best;
    var bestScore = 0;

    _entries.forEach((key, info) {
      final score = _score(normalised, key);
      if (score > bestScore) {
        bestScore = score;
        best = info;
      }
    });

    // Require a real keyword hit rather than an incidental character overlap.
    if (best != null && bestScore >= 2) return best!;
    return unknown;
  }

  static String _normalise(String raw) => raw
      .toLowerCase()
      .replaceAll('___', ' ')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'[^a-z ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Number of key words from [key] that appear in [label], with a bonus for
  /// the full phrase appearing contiguously.
  static int _score(String label, String key) {
    final keyWords = key.split(' ').where((w) => w.length > 2).toList();
    if (keyWords.isEmpty) return 0;

    var hits = 0;
    for (final word in keyWords) {
      if (label.contains(word)) hits++;
    }
    if (hits == 0) return 0;

    // Full phrase match is a much stronger signal than scattered words.
    final phraseBonus = label.contains(key) ? keyWords.length + 1 : 0;
    return hits + phraseBonus;
  }
}
